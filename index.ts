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
    // Read a PORT environment variable and ensure it's a positive integer.
    // An EnvVarError will be thrown if the variable is not set, or if it
    // is not a positive integer.
    // const PORT: number = env.get('PORT').required().asIntPositive();

    console.log("ENVIRONMENT START");
//    console.dir(process.env);
    console.log(`TEAM_SPEND_ALERT is ${process.env["TEAM_SPEND_ALERT"]}`);
    console.log(`TEAM_SPEND_ACTION is ${process.env["TEAM_SPEND_ACTION"]}`);
    console.log("ENVIRONMENT END");

    // Generate timestamped key
    const key = `lambda-run-${currentTimestamp}.json`;

    // Create object content
    const content = {
      timestamp: currentTimestamp,
      message: "Lambda function executed",
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
