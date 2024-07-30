const ZERO = 0;
const TEN = 10;
const EIGHTY = 80;

import { Context, APIGatewayProxyResult, APIGatewayEvent } from "aws-lambda";
//import { LambdaClient, GetFunctionConfigurationCommand, UpdateFunctionConfigurationCommand } from "@aws-sdk/client-lambda";
import { CostExplorerClient, GetAnomalySubscriptionsCommand, UpdateAnomalySubscriptionCommand } from "@aws-sdk/client-cost-explorer";
// see https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/cost-explorer/

class MockS3Client {
  async send(command: any) {
    console.log(`Mock S3 operation: ${command.constructor.name}`);
    return { success: true };
  }
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
    // const Region_list = RC_list.map((x) => x[0].Region);
    // console.log("Region_list");
    // console.dir(Region_list);
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
      MonitorArn: "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34",
      MaxResults: 20
    };
    const gasccommand = new GetAnomalySubscriptionsCommand(cinput);
    const cresponse = await cclient.send(gasccommand);
    const SubscriptionArn = cresponse.AnomalySubscriptions[0].SubscriptionArn;
    const ThresholdExpression = cresponse.AnomalySubscriptions[0].ThresholdExpression;
    console.log("Original Anomaly Subscription ThresholdExpression is ");
    console.dir(ThresholdExpression);

    const asc_values = cresponse.AnomalySubscriptions[0].ThresholdExpression.Dimensions.Values;
    const current_alert = asc_values[0] || TEN;
    const TEAM_SPEND_ALERT: number = parameter_alert || Number(current_alert);
    const TEAM_SPEND_ACTION: number = parameter_action || EIGHTY;

    if (current_alert != TEAM_SPEND_ALERT) {
      const cas0 = cresponse.AnomalySubscriptions[0];

      cas0.ThresholdExpression.Dimensions.Values = [ `${TEAM_SPEND_ALERT}` ];
      const cinput2 = { 
        ThresholdExpression: cas0.ThresholdExpression,
        SubscriptionArn: cas0.SubscriptionArn
      }

      const ccommand = new UpdateAnomalySubscriptionCommand(cinput2);
      const cresponse2 = await cclient.send(ccommand);
    }

    // Generate timestamped key
    const key = `lambda-run-${currentTimestamp}.json`;

    // Create object content
    const content = {
      timestamp: currentTimestamp,
      message: "Lambda function executed",
      alert: TEAM_SPEND_ALERT,
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
        alert: TEAM_SPEND_ALERT,
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
