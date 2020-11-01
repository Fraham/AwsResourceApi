var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function getLambdaMetric(task) {
        var cloudWatch = new AWS.CloudWatch({
            apiVersion: '2010-08-01',
            region: process.env.AWS_REGION
        });

        var endTime = new Date();
        var startTime = new Date();
        startTime.setMinutes(startTime.getMinutes() - task.Period);

        var functionName = task.functionArn.split(':').slice(-1)[0];

        var params = {
            EndTime: endTime,
            MetricName: task.Metric,
            Namespace: 'AWS/Lambda',
            Period: task.Period * 60,
            StartTime: startTime,
            Dimensions: [
                {
                    Name: 'FunctionName',
                    Value: functionName
                }
            ],
            Statistics: [
                "Sum"
            ]
        };

        return cloudWatch.getMetricStatistics(params).promise();
    }

    const functionArn = helper.getParameter(event, "functionArn");

    if (!functionArn) {
        throw "No function arn passed";
    }

    var getMetrics = [{
        "Metric": "Invocations",
        "Period": 60,
        "functionArn": functionArn
    },
    {
        "Metric": "Errors",
        "Period": 60,
        "functionArn": functionArn
    },
    {
        "Metric": "Throttles",
        "Period": 60,
        "functionArn": functionArn
    },
    {
        "Metric": "Invocations",
        "Period": 10,
        "functionArn": functionArn
    },
    {
        "Metric": "Errors",
        "Period": 10,
        "functionArn": functionArn
    },
    {
        "Metric": "Throttles",
        "Period": 10,
        "functionArn": functionArn
    }];

    const getMetricsTasks = getMetrics.map(getLambdaMetric);

    var getMetricsResults = await Promise.all(getMetricsTasks);

    var resultMetrics = [];
    for (let i = 0; i < getMetricsResults.length; i++) {
        const element = getMetricsResults[i];

        resultMetrics.push({
            "Metric": getMetrics[i].Metric,
            "Period": getMetrics[i].Period,
            "Data": element.Datapoints[0] ? element.Datapoints[0].Sum : 0
        });
    }

    var result = {
        Metrics: resultMetrics
    };

    console.log(JSON.stringify(result));

    return {
        statusCode: 200,
        body: JSON.stringify(result)
    };
};
