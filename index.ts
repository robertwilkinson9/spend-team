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

const MonitorARN = "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34";
const MAXResults = TWENTY;

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

/*
const delete_alert_subscriptions = async alert_arns => {
      for (const arn of alert_arns) {
         console.log(`DELETING SUBSCRIPTION ${arn}`);
	 const input = {"SubscriptionArn": arn}
         const command = new DeleteAnomalySubscriptionCommand(input);
	 const response = await cclient.send(command);
	 console.dir(response);
      }
};
      
const add_new_alert_subscription = async (old_subscription: AnomalySubscription, percentage: string, value:number) => {
	const subscription_name = `TeamSpend${percentage}`;
	old_subscription.SubscriptionName = subscription_name;
	old_subscription.ThresholdExpression.Dimensions.Values.length = 0; // clear the current values
	old_subscription.ThresholdExpression.Dimensions.Values.push(`${value}`);
	console.dir(old_subscription);
	console.dir(old_subscription.ThresholdExpression);
//	const input = { old_subscription };
//	const command = new CreateAnomalySubscriptionCommand(input);
//	const response = await cclient.send(command);

	const input = { // CreateAnomalySubscriptionRequest
    	  AnomalySubscription: { // AnomalySubscription
	  SubscriptionArn: 'arn:aws:ce::778666285893:anomalysubscription/d2b9a01a-41a4-4dd1-9ed3-085ee7bd564b',
	    AccountId: '778666285893',
	     MonitorArnList: [
	       'arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34'
	     ],
	    Subscribers: [
	     {
	       Address: 'arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert',
	       Status: 'CONFIRMED',
	       Type: 'SNS'
	     }
	    ],
	    Frequency: 'IMMEDIATE',
            SubscriptionName: subscription_name,
            ThresholdExpression: {
	      Dimensions: {
	        Key: 'ANOMALY_TOTAL_IMPACT_ABSOLUTE',
  	        MatchOptions: ["GREATER_THAN_OR_EQUAL"],
    	        Values: [value]
              }
            }
	  }
        }

//	},
//	Tags: {
//  	  Key: "Team",
// 	  Values: [ "Spend"],
	const command = new CreateAnomalySubscriptionCommand(input);
	const response = await cclient.send(command);

	// { // CreateAnomalySubscriptionResponse
        // SubscriptionArn: "STRING_VALUE", // required
        // };
};
*/

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
      MonitorArn: MonitorARN,
      MaxResults: MAXResults
    };
    const gasccommand = new GetAnomalySubscriptionsCommand(cinput);
    const cresponse = await cclient.send(gasccommand);
    const cas = cresponse.AnomalySubscriptions;

    let alert_arns: string[] = [];
    let alert_names: string[] = [];
    let alert_tes = [];
    let action_arn: string;
    let current_action_te;
    let current_action_dimensions;
    let current_action_value = 0;

    cas.forEach(subscription => {
      console.dir(subscription);
      const address = subscription.Subscribers[0].Address; // subscribers should be a list too? XXX
      if (address.endsWith("TeamSpendAction")) {
        console.log("ACTION FOUND");
	action_arn = subscription.SubscriptionArn;
	current_action_te = subscription.ThresholdExpression;
	current_action_dimensions = subscription.ThresholdExpression.Dimensions;
	current_action_value = Number(subscription.ThresholdExpression.Dimensions.Values[0]); // no idea why Values is a list ATM XXX
      } else if (address.endsWith("TeamSpendAlert")) {
        console.log("ALERT FOUND");
	alert_names.push(subscription.SubscriptionName);
	alert_arns.push(subscription.SubscriptionArn);
	alert_tes.push(subscription.ThresholdExpression);
      } else {
        console.log("XXX FOUND");
      }
    });

    console.log(`ACtion ARN is ${action_arn}`);
    console.log(`CURRENT ACtion VALUe is ${current_action_value}`);
    console.log(`Alert ARNs are `);
    console.dir(alert_arns);

    const TEAM_SPEND_ACTION: number = parameter_action || FIFTY;
    console.log(`current_action_value is ${current_action_value} TEAM_SPEND_ACTION is ${TEAM_SPEND_ACTION}`);

    if (current_action_value != TEAM_SPEND_ACTION) {
      current_action_te.Dimensions.Values = [ `${TEAM_SPEND_ACTION}` ];
      const cinput2 = { 
        ThresholdExpression: current_action_te,
        SubscriptionArn: action_arn
      }

      const ccommand = new UpdateAnomalySubscriptionCommand(cinput2);
      const cresponse2 = await cclient.send(ccommand);

      // compute 20%, 40%, 60%, 80% of new TSA
      const onepercent = TEAM_SPEND_ACTION / 100;

      for (let i = 0; i < alert_arns.length; i++) {
         const arn = alert_arns[i];
         const alert_name = alert_names[i];
         const alert_value = Number(alert_name.substring(9)) * onepercent;
         const alert_te = alert_tes[i];
         alert_te.Dimensions.Values = [ `${alert_value}` ];

         console.log(`UPDATING SUBSCRIPTION ${arn} iVALUE ${alert_value}`);
	 const input = {SubscriptionArn: arn, ThresholdExpression: alert_te}
         const command = new UpdateAnomalySubscriptionCommand(input);
	 const response = await cclient.send(command);
	 console.dir(response);
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
