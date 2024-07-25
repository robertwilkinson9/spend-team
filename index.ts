import { Context, APIGatewayProxyResult, APIGatewayEvent } from "aws-lambda";
import * as env from 'env-var';

class MockS3Client {
  async send(command: any) {
    console.log(`Mock S3 operation: ${command.constructor.name}`);
    return { success: true };
  }
}

const s3Client = new MockS3Client();
const bucketName = "timebucketstamp";

// Store timestamps of Lambda invocations
let invocationTimestamps: string[] = [];

export const handler = async (
  event: APIGatewayEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  const currentTimestamp = new Date().toISOString();
  invocationTimestamps.push(currentTimestamp);

  console.log("Lambda function invocation timestamps:");
  invocationTimestamps.forEach((timestamp, index) => {
    console.log(`Run ${index + 1}: ${timestamp}`);
  });

  try {
    // Read TEAM_SPEND environment variables and provide defaults if not supplied
    const TEAM_SPEND_ALERT: number = env.get('TEAM_SPEND_ALERT').default('10').asIntPositive();
    const TEAM_SPEND_ACTION: number = env.get('TEAM_SPEND_ACTION').default('50').asIntPositive();

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
