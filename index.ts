import { Context, APIGatewayProxyResult, APIGatewayEvent } from "aws-lambda";
//import { LambdaClient, GetFunctionConfigurationCommand, UpdateFunctionConfigurationCommand } from "@aws-sdk/client-lambda";
import { CostExplorerClient, GetAnomalySubscriptionsCommand, CreateAnomalySubscriptionCommand, UpdateAnomalySubscriptionCommand, DeleteAnomalySubscriptionCommand } from "@aws-sdk/client-cost-explorer";
// see https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cost-explorer/

const ZERO = 0;
const TEN = 10;
const TWENTY = 20;
const FIFTY = 50;
const EIGHTY = 80;
const HUNDRED = 100;

const TEAMSPENDLEN = 9; // length of TeamSpend string

const MonitorARN = "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34";
const MAXResults = TWENTY;

const DEFAULT_SPEND_LIMIT = FIFTY;

class MockS3Client {
  async send(command: any) {
    console.log(`Mock S3 operation: ${command.constructor.name}`);
    return { success: true };
  }
}

export interface AnomalySubscription {
  SubscriptionArn: string
  AccountId: string
  MonitorArnList: string[]
  Subscribers: Subscriber[]
  Threshold: number
  Frequency: string
  SubscriptionName: string
  ThresholdExpression: ThresholdExpression
}

export interface Subscriber {
  Address: string
  Type: string
  Status: string
}

export interface ThresholdExpression {
  Dimensions: Dimensions
}

export interface Dimensions {
  Key: string
  Values: string[]
  MatchOptions: string[]
}

export interface AnomaliesList {
  Anomalies: Anomaly[]
}

export interface Anomaly {
  AnomalyId: string
  AnomalyStartDate: string
  AnomalyEndDate: string
  DimensionValue: string
  RootCauses: RootCause[]
  AnomalyScore: AnomalyScore
  Impact: Impact
  MonitorArn: string
}

export interface RootCause {
  Service: string
  Region?: string
  LinkedAccount: string
  UsageType?: string
  LinkedAccountName: string
}

export interface AnomalyScore {
  MaxScore: number
  CurrentScore: number
}

export interface Impact {
  MaxImpact: number
  TotalImpact: number
  TotalActualSpend: number
  TotalExpectedSpend: number
  TotalImpactPercentage?: number
}

export interface ParameterSetting{
  parameters: Parameters
}

export interface Parameters {
  alert: number
  action: number
}

type EventType = AnomaliesList | ParameterSetting;

const s3Client = new MockS3Client();
const bucketName = "timebucketstamp";

const config = { region: "eu-west-2",
	         credentials: {
		        accessKeyId: process.env["AWS_ACCESS_KEY_ID"],
			secretAccessKey: process.env["AWS_SECRET_ACCESS_KEY"],
			sessionToken: process.env["AWS_SESSION_TOKEN"]
		 }
};

const cclient = new CostExplorerClient(config);
//const lclient = new LambdaClient(config);

// Store timestamps of Lambda invocations
let invocationTimestamps: string[] = [];

//  event: APIGatewayEvent,
export const handler = async (
  event: EventType,
  context: Context
): Promise<APIGatewayProxyResult> => {

  console.log("EVENT is ");
  console.dir(event);

  if (("Anomalies" in event) && (event.Anomalies)) {
    console.log(`HAVE ANOMALIES`);
    const RC_list = event.Anomalies.map((x) => x.RootCauses);
    console.log("RC_list");
    console.dir(RC_list);
    const UsageType_list = RC_list.map((x) => x[0].UsageType);
    console.log("UsageType_list");
    console.dir(UsageType_list);
  }

  let parameter_alert = 0;
  let parameter_action = 0;
  if (("parameters" in event) && (event.parameters)) {
    if (event.parameters.alert) {
      parameter_alert = event.parameters.alert;
    }
    if (event.parameters.action) {
      parameter_action = event.parameters.action;
    }
  }
  console.log(`parameter_alert is ${parameter_alert}, parameter_action is ${parameter_action}`);

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

    const cinput = { // GetAnomalySubscriptionsRequest
      MonitorArn: MonitorARN,
      MaxResults: MAXResults
    };
    const gasccommand = new GetAnomalySubscriptionsCommand(cinput);
    const cresponse = await cclient.send(gasccommand);

    let alert_details = [];
    let action_arn: string;
    let current_action_te;
    let current_action_value = 0;

    for (const subscription of cresponse.AnomalySubscriptions) {
      const address = subscription.Subscribers[0].Address; // subscribers should be a list too? XXX
      if (address.endsWith("TeamSpendAction")) {
        console.log("ACTION FOUND");
	action_arn = subscription.SubscriptionArn;
	current_action_te = subscription.ThresholdExpression;
	current_action_value = Number(subscription.ThresholdExpression.Dimensions.Values[0]); // no idea why Values is a list ATM XXX
      } else if (address.endsWith("TeamSpendAlert")) {
        console.log(`ALERT FOUND -> ${subscription.SubscriptionName}`);
        const sub_details = {name: subscription.SubscriptionName, arn: subscription.SubscriptionArn, te: subscription.ThresholdExpression};
	alert_details.push(sub_details);
      } else {
        console.log("XXX FOUND");
      }
    }

    const TEAM_SPEND_ACTION: number = parameter_action || DEFAULT_SPEND_LIMIT;

    if (current_action_value != TEAM_SPEND_ACTION) {
      current_action_te.Dimensions.Values = [ `${TEAM_SPEND_ACTION}` ];
      const cinput2 = { 
        ThresholdExpression: current_action_te,
        SubscriptionArn: action_arn
      }

      const ccommand = new UpdateAnomalySubscriptionCommand(cinput2);
      const cresponse2 = await cclient.send(ccommand);

      // now compute 20%, 40%, 60%, 80% of new TeamSpendAction and update alerts
      const onepercent = TEAM_SPEND_ACTION / 100;

      for (const detail of alert_details) {
        const arn = detail.arn;
        const value = Number(detail.name.substring(TEAMSPENDLEN)) * onepercent;
        const te = detail.te;
        te.Dimensions.Values = [ `${value}` ];

        const input = {SubscriptionArn: arn, ThresholdExpression: te}
        const command = new UpdateAnomalySubscriptionCommand(input);
        const response = await cclient.send(command);
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

    // Simulate putting object in S3 bucket
    await s3Client.send({
      constructor: { name: "PutObjectCommand" },
      Bucket: bucketName,
      Key: key,
      Body: JSON.stringify(content),
      ContentType: "application/json",
    });

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
