import { Context, APIGatewayProxyResult, APIGatewayEvent } from "aws-lambda";
//import { LambdaClient, GetFunctionConfigurationCommand, UpdateFunctionConfigurationCommand } from "@aws-sdk/client-lambda";
import {
  CostExplorerClient,
  GetAnomalySubscriptionsCommand,
  CreateAnomalySubscriptionCommand,
  UpdateAnomalySubscriptionCommand,
  DeleteAnomalySubscriptionCommand,
} from "@aws-sdk/client-cost-explorer";
// see https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cost-explorer/
import {
  OrganizationsClient,
  CloseAccountCommand,
} from "@aws-sdk/client-organizations"; // ES Modules import
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const ZERO = 0;
const TEN = 10;
const TWENTY = 20;
const FIFTY = 50;
const EIGHTY = 80;
const HUNDRED = 100;

const TEAMSPENDLEN = 9; // length of TeamSpend string

const MonitorARN =
  "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34";
const MAXResults = TWENTY;

export interface AnomalySubscription {
  SubscriptionArn: string;
  AccountId: string;
  MonitorArnList: string[];
  Subscribers: Subscriber[];
  Threshold: number;
  Frequency: string;
  SubscriptionName: string;
  ThresholdExpression: ThresholdExpression;
}

export interface Subscriber {
  Address: string;
  Type: string;
  Status: string;
}

export interface ThresholdExpression {
  Dimensions: Dimensions;
}

export interface Dimensions {
  Key: string;
  Values: string[];
  MatchOptions: string[];
}

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

type EventType = AnomaliesList | Anomaly | ParameterSetting;

const bucketName = "timebucketstamp";

const config = {
  region: "eu-west-2",
  credentials: {
    accessKeyId: process.env["AWS_ACCESS_KEY_ID"],
    secretAccessKey: process.env["AWS_SECRET_ACCESS_KEY"],
    sessionToken: process.env["AWS_SESSION_TOKEN"],
  },
};

const s3Client = new S3Client(config);
const cclient = new CostExplorerClient(config);
//const lclient = new LambdaClient(config);
const oclient = new OrganizationsClient(config);

// Store timestamps of Lambda invocations
let invocationTimestamps: string[] = [];

//  event: APIGatewayEvent,
export const handler = async (
  event: EventType,
  context: Context
): Promise<APIGatewayProxyResult> => {
  console.log("EVENT is ");
  console.dir(event);

  let action_set = false;
  let TEAM_SPEND_ACTION;

  let ARClist;
  if ("Anomalies" in event && event.Anomalies) {
    console.log(`HAVE ANOMALIES`);
    ARClist = event.Anomalies.map((x) => x.RootCauses);
    console.log("ARClist");
    console.dir(ARClist);
    console.log(`ARClist length is ${ARClist.length}`);
  } else {
    if ("RootCauses" in event && event.RootCauses) {
      ARClist = [event.RootCauses];
    } else if ("parameters" in event && event.parameters) {
      if (event.parameters.action) {
        TEAM_SPEND_ACTION = Number(event.parameters.action);
        action_set = true;
      }
    }
  }
  const currentTimestamp = new Date().toISOString();
  invocationTimestamps.push(currentTimestamp);

  console.log("Lambda function invocation timestamps:");
  invocationTimestamps.forEach((timestamp, index) => {
    console.log(`Run ${index + 1}: ${timestamp}`);
  });

  try {
    //    const linput = { // GetFunctionConfigurationRequest
    //	FunctionName: "arn:aws:lambda:eu-west-2:778666285893:function:spend-team-lambda"
    //    };
    //    const lcommand = new GetFunctionConfigurationCommand(linput);
    //    const lresponse = await lclient.send(lcommand);
    //    console.dir(lresponse);

    //    const uclient = new LambdaClient(config);
    //    const ucommand = new UpdateFunctionConfigurationCommand(lresponse);
    //    const uresponse = await uclient.send(ucommand);

    if (action_set) {
      let alert_details = [];
      let action_arn: string | undefined = "";
      let current_action_te;

      const cinput = {
        // GetAnomalySubscriptionsRequest
        MonitorArn: MonitorARN,
        MaxResults: MAXResults,
      };
      const gasccommand = new GetAnomalySubscriptionsCommand(cinput);
      const cresponse = await cclient.send(gasccommand);

      if (cresponse && cresponse.AnomalySubscriptions) {
        for (const subscription of cresponse.AnomalySubscriptions) {
          if (subscription.Subscribers) {
            for (const subscriber of subscription.Subscribers) {
              const address = subscriber.Address || "NULL ADDRESS";
              if (address.endsWith("TeamSpendAction")) {
                console.log("ACTION FOUND");
                action_arn = subscription.SubscriptionArn;
                current_action_te = subscription.ThresholdExpression;
              } else if (address.endsWith("TeamSpendAlert")) {
                console.log(`ALERT FOUND -> ${subscription.SubscriptionName}`);
                const sub_details = {
                  name: subscription.SubscriptionName,
                  arn: subscription.SubscriptionArn,
                  te: subscription.ThresholdExpression,
                };
                alert_details.push(sub_details);
              } else {
                console.log(`XXX FOUND ADDRESS ${address}`);
              }
            }
          } else {
            console.log(`XXX - NO SUBSCRIBERS`);
          }
        }
      } else {
        console.log(`XXX - NO RESPONSE OR SUBSCRIPTIONS`);
      }

      if (current_action_te && current_action_te.Dimensions) {
        current_action_te.Dimensions.Values = [`${TEAM_SPEND_ACTION}`];
      }
      const cinput2 = {
        ThresholdExpression: current_action_te,
        SubscriptionArn: action_arn
      };

      const ccommand = new UpdateAnomalySubscriptionCommand(cinput2);
      const cresponse2 = await cclient.send(ccommand);

      // now compute 20%, 40%, 60%, 80% of new TeamSpendAction and update alerts
      const onepercent = TEAM_SPEND_ACTION ? TEAM_SPEND_ACTION / 100 : 0;

      for (const detail of alert_details) {
        const arn = detail.arn;
        const value = Number(detail.name?.substring(TEAMSPENDLEN)) * onepercent;
        const te = detail.te;
        if (te && te.Dimensions) {
          te.Dimensions.Values = [`${value}`];
        }
        const input = { SubscriptionArn: arn, ThresholdExpression: te };
        const command = new UpdateAnomalySubscriptionCommand(input);
        const response = await cclient.send(command);
      }
    } else {
      // action is not set so here we add code to suspend account IDs
      if (ARClist && ARClist.length) {
        let closed_accounts: Set<string> = new Set();
        for (const RC_list of ARClist) {
          for (const root_cause of RC_list) {
            const ac_id_to_close = root_cause.LinkedAccount;
            if (!closed_accounts.has(ac_id_to_close)) {
              console.log(`Would close Account ${ac_id_to_close}`);
              /*
              const input = { // CloseAccountRequest
                AccountId: ac_id_to_close
              };
              const command = new CloseAccountCommand(input);
              const response = await client.send(command);
*/
              closed_accounts.add(ac_id_to_close);
            }
          }
        }
      }
    }

    // Generate timestamped key
    const key = `lambda-run-${currentTimestamp}.json`;

    // Create object content
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

    console.log(`Object ${key} simulated creation in bucket ${bucketName}`);

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
