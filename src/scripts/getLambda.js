var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function getFunction(functionArn) {
        var lambda = new AWS.Lambda({
            apiVersion: '2015-03-31',
            region: process.env.AWS_REGION
        });

        var params = {
            FunctionName: functionArn
        };

        return lambda.getFunction(params).promise();
    }
    
    async function callLambdaMetrics(functionArn) {
        var lambda = new AWS.Lambda({
            apiVersion: '2015-03-31',
            region: process.env.AWS_REGION
        });

        var params = {
            FunctionName: process.env.GET_LAMBDA_METRICS_ARN,
            InvocationType: "RequestResponse",
            Payload: JSON.stringify({
                functionArn: functionArn
            })
        };

        return lambda.invoke(params).promise();
    }

    async function callLambdaAlarms(functionArn) {
        var lambda = new AWS.Lambda({
            apiVersion: '2015-03-31',
            region: process.env.AWS_REGION
        });

        var params = {
            FunctionName: process.env.GET_LAMBDA_ALARMS_ARN,
            InvocationType: "RequestResponse",
            Payload: JSON.stringify({
                functionArn: functionArn
            })
        };

        return lambda.invoke(params).promise();
    }
    
    var functionArn = null;

    if (event) {

        if (event.body) {
            let body = helper.parseJsonString(event.body);

            if (body.functionArn) {
                functionArn = body.functionArn;
            }
        }

        if (event.functionArn) {
            functionArn = event.functionArn;
        }
        
        if (event.pathParameters && event.pathParameters.functionarn){
            functionArn = event.pathParameters.functionarn;
        }
    }

    if (!functionArn) {
        throw "No function arn passed";
    }

    var getFunctionPromise = getFunction(functionArn);
    var callLambdaMetricsPromise = callLambdaMetrics(functionArn);
    var callLambdaAlarmsPromise = callLambdaAlarms(functionArn);

    var getFunctionResult = await getFunctionPromise;
    var callLambdaMetricsResults = await callLambdaMetricsPromise;
    var callLambdaAlarmsResults = await callLambdaAlarmsPromise;

    var result = getFunctionResult;
    result.Metrics = helper.parseJsonString(helper.parseJsonString(callLambdaMetricsResults.Payload).body);
    result.Alarms = helper.parseJsonString(helper.parseJsonString(callLambdaAlarmsResults.Payload).body);    

    return {
        statusCode: 200,
        body: JSON.stringify(result)
    };
};
