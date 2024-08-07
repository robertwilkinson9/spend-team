import { Context, APIGatewayProxyResult } from "aws-lambda";
import {
  CostExplorerClient,
  GetAnomalySubscriptionsCommand,
  UpdateAnomalySubscriptionCommand,
} from "@aws-sdk/client-cost-explorer";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

import { GetAnomalySubscriptionsCommandOutput } from "@aws-sdk/client-cost-explorer";
import {
  OrganizationsClient,
  CloseAccountCommand,
} from "@aws-sdk/client-organizations";

export const ZERO = 0;
export const TEN = 10;
export const TWENTY = 20;
export const FIFTY = 50;
export const EIGHTY = 80;
export const HUNDRED = 100;

export const TEAMSPENDLEN = 9; // length of TeamSpend string

export const MonitorARN =
  "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34";
export const MAXResults = TWENTY;

export interface AnomaliesList {
  Anomalies: Anomaly[];
}

export interface Anomaly {
  AnomalyId: string;
  AnomalyStartDate: string;
  AnomalyEndDate: string;
  DimensionValue: string;
  RootCauses: RootCause[];
  AnomalyScore: AnomalyScore;
  Impact: Impact;
  MonitorArn: string;
}

export interface RootCause {
  Service: string;
  Region?: string;
  LinkedAccount: string;
  UsageType?: string;
  LinkedAccountName: string;
}

export interface AnomalyScore {
  MaxScore: number;
  CurrentScore: number;
}

export interface Impact {
  MaxImpact: number;
  TotalImpact: number;
  TotalActualSpend: number;
  TotalExpectedSpend: number;
  TotalImpactPercentage?: number;
}

export interface ParameterSetting {
  parameters: Parameters;
}

export interface Parameters {
  alert: number;
  action: number;
}

export type EventType = AnomaliesList | Anomaly | ParameterSetting;

// Extract the AnomalySubscription type from the AWS SDK type
export type AnomalySubscription = NonNullable<
  GetAnomalySubscriptionsCommandOutput["AnomalySubscriptions"]
>[number];

// Extract the ThresholdExpression type from AnomalySubscription
export type ThresholdExpression = NonNullable<
  AnomalySubscription["ThresholdExpression"]
>;

const config = {
  region: "eu-west-2",
  credentials: {
    accessKeyId: process.env["AWS_ACCESS_KEY_ID"],
    secretAccessKey: process.env["AWS_SECRET_ACCESS_KEY"],
    sessionToken: process.env["AWS_SESSION_TOKEN"],
  },
};

const s3Client = new S3Client(config);
const bucketName = "timebucketstamp";

const cclient = new CostExplorerClient(config);
const oclient = new OrganizationsClient(config);

let invocationTimestamps: string[] = [];

export const handler = async (
  event: EventType,
  context: Context
): Promise<APIGatewayProxyResult> => {
  console.log("EVENT is ", JSON.stringify(event, null, 2));

  let action_set = false;
  let TEAM_SPEND_ACTION: number | undefined;

  let ARClist: RootCause[][] = [];
  if ("Anomalies" in event && Array.isArray(event.Anomalies)) {
    console.log(`HAVE ANOMALIES`);
    ARClist = event.Anomalies.map((x) => x.RootCauses);
    console.log("ARClist", JSON.stringify(ARClist, null, 2));
    console.log(`ARClist length is ${ARClist.length}`);
  } else if ("RootCauses" in event && Array.isArray(event.RootCauses)) {
    ARClist = [event.RootCauses];
  } else if ("parameters" in event && event.parameters.action) {
    TEAM_SPEND_ACTION = Number(event.parameters.action);
    action_set = true;
  }

  const currentTimestamp = new Date().toISOString();
  invocationTimestamps.push(currentTimestamp);

  console.log("Lambda function invocation timestamps:");
  invocationTimestamps.forEach((timestamp, index) => {
    console.log(`Run ${index + 1}: ${timestamp}`);
  });

  try {
    if (action_set && TEAM_SPEND_ACTION !== undefined) {
      let alert_details: {
        name: string;
        arn: string;
        te: ThresholdExpression;
      }[] = [];
      let action_arn: string | undefined;
      let current_action_te: ThresholdExpression | undefined;

      const cinput = {
        MonitorArn: MonitorARN,
        MaxResults: MAXResults,
      };
      const gasccommand = new GetAnomalySubscriptionsCommand(cinput);
      const cresponse = await cclient.send(gasccommand);

      if (cresponse.AnomalySubscriptions) {
        for (const subscription of cresponse.AnomalySubscriptions) {
          if (subscription.Subscribers && subscription.Subscribers.length > 0) {
            const address = subscription.Subscribers[0].Address;
            if (address && address.endsWith("TeamSpendAction")) {
              console.log("ACTION FOUND");
              action_arn = subscription.SubscriptionArn;
              current_action_te = subscription.ThresholdExpression;
            } else if (address && address.endsWith("TeamSpendAlert")) {
              console.log(`ALERT FOUND -> ${subscription.SubscriptionName}`);
              if (
                subscription.SubscriptionName &&
                subscription.SubscriptionArn &&
                subscription.ThresholdExpression
              ) {
                alert_details.push({
                  name: subscription.SubscriptionName,
                  arn: subscription.SubscriptionArn,
                  te: subscription.ThresholdExpression,
                });
              }
            } else {
              console.log("XXX FOUND");
            }
          }
        }
      }

      if (current_action_te && action_arn) {
        if (current_action_te.Dimensions) {
          current_action_te.Dimensions.Values = [`${TEAM_SPEND_ACTION}`];
        } else {
          console.warn("Action ThresholdExpression Dimensions is undefined");
        }

        const cinput2 = {
          ThresholdExpression: current_action_te,
          SubscriptionArn: action_arn,
        };

        const ccommand = new UpdateAnomalySubscriptionCommand(cinput2);
        await cclient.send(ccommand);

        const onepercent = TEAM_SPEND_ACTION / 100;

        for (const detail of alert_details) {
          const value =
            Number(detail.name.substring(TEAMSPENDLEN)) * onepercent;
          if (detail.te.Dimensions) {
            detail.te.Dimensions.Values = [`${value}`];
          } else {
            console.warn(
              `Alert ThresholdExpression Dimensions is undefined for ${detail.name}`
            );
          }

          const input = {
            SubscriptionArn: detail.arn,
            ThresholdExpression: detail.te,
          };
          const command = new UpdateAnomalySubscriptionCommand(input);
          await cclient.send(command);
        }
      }
    } else {
      if (ARClist.length > 0) {
        const closed_accounts: Set<string> = new Set();
        for (const RC_list of ARClist) {
          for (const root_cause of RC_list) {
            const ac_id_to_close = root_cause.LinkedAccount;
            if (!closed_accounts.has(ac_id_to_close)) {
              console.log(`Would close Account ${ac_id_to_close}`);
              closed_accounts.add(ac_id_to_close);
            }
          }
        }
      }
    }

    const key = `lambda-run-${currentTimestamp}.json`;

    const content = {
      timestamp: currentTimestamp,
      message: "Lambda function executed",
      action: TEAM_SPEND_ACTION,
      event: event,
    };

    const putCommand = new PutObjectCommand({
      Bucket: bucketName,
      Key: key,
      Body: JSON.stringify(content),
      ContentType: "application/json",
    });

    await s3Client.send(putCommand);

    console.log(`Object ${key} created in bucket ${bucketName}`);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Hello Haseb!",
        currentTimestamp: currentTimestamp,
        allInvocations: invocationTimestamps,
        action: TEAM_SPEND_ACTION,
        s3Object: `s3://${bucketName}/${key}`,
      }),
    };
  } catch (error) {
    console.error("Error:", error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "An error occurred",
        error: error instanceof Error ? error.message : String(error),
      }),
    };
  }
};
