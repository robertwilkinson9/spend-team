import { Context, APIGatewayProxyResult, APIGatewayEvent } from 'aws-lambda';

export const handler = async (event: APIGatewayEvent, context: Context): Promise<APIGatewayProxyResult> => {
    console.log(`Event: ${JSON.stringify(event, null, 2)}`);
    console.log(`Anomalies`);
    console.dir(event.Anomalies[0]);
    console.log(`First root cause`);
    console.dir(event.Anomalies[0].RootCauses[0]);
    console.log(`First Region is ${event.Anomalies[0].RootCauses[0].Region}`);

//    console.log(`First Linked Account`);
//    console.log(event.Anomalies[0].RootCauses[0].LinkedAccount);

    console.log(`Context: ${JSON.stringify(context, null, 2)}`);
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Hello World!',
        }),
    };
};
