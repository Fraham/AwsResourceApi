var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function getLambdaAlarms(task) {
        var cloudWatch = new AWS.CloudWatch({
            apiVersion: '2010-08-01',
            region: process.env.AWS_REGION
        });

        var functionName = task.functionArn.split(':').slice(-1)[0];

        var params = {
            Dimensions: [
                {
                    Name: 'FunctionName',
                    Value: functionName
                }
            ],
            Namespace: 'AWS/Lambda',
            MetricName: task.Metric
        };

        return cloudWatch.describeAlarmsForMetric(params).promise();
    }

    var functionArn = null;

    event = helper.parseJsonString(event);

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

        if (event.pathParameters && event.pathParameters.functionarn) {
            functionArn = event.pathParameters.functionarn;
        }
    }

    if (!functionArn) {
        throw "No function arn passed";
    }

    var cloudWatchMetrics = [
        {
            "Metric": "Invocations",
            "functionArn": functionArn
        },
        {
            "Metric": "Errors",
            "functionArn": functionArn
        },
        {
            "Metric": "Throttles",
            "functionArn": functionArn
        }];

    const getLambdaAlarmsTasks = cloudWatchMetrics.map(getLambdaAlarms);

    var getLambdaAlarmsResults = await Promise.all(getLambdaAlarmsTasks);

    console.log(JSON.stringify(getLambdaAlarmsResults));

    var alarmArns = [];

    getLambdaAlarmsResults.forEach(element => {
        element.MetricAlarms.forEach(alarm => {
            alarmArns.push(alarm.AlarmArn);
        });
    });

    var result = {
        AlarmArns: alarmArns
    };

    console.log(result);

    return {
        statusCode: 200,
        body: JSON.stringify(result)
    };
};