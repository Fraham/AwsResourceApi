var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

exports.handler = async (event) => {

    async function listAlarms(nextToken) {
        var lambda = new AWS.CloudWatch({
            apiVersion: '2015-03-31',
            region: process.env.AWS_REGION
        });

        var params = {
            MaxRecords: 10,
            AlarmTypes: [
                "CompositeAlarm",
                "MetricAlarm"
            ]
        };

        if (nextToken) {
            params.NextToken = nextToken;
        }

        return lambda.describeAlarms(params).promise();
    }

    async function listAllAlarms() {
        const alarms = [];
        var nextToken = null;
        var gotAllAlarms = false;

        while (!gotAllAlarms) {
            var listAlarmsPromise = listAlarms(nextToken);

            var listAlarmsResult = await listAlarmsPromise;

            if (!listAlarmsResult) {
                continue;
            }

            listAlarmsResult.MetricAlarms.forEach(alarm => {
                alarms.push({
                    'ARN': alarm.AlarmArn,
                    'Name': alarm.AlarmName,
                    'State': alarm.StateValue,
                    'StateUpdatedTimestamp': alarm.StateUpdatedTimestamp,
                    'Type': 'Metric'
                });
            });

            listAlarmsResult.CompositeAlarms.forEach(alarm => {
                alarms.push({
                    'ARN': alarm.AlarmArn,
                    'Name': alarm.AlarmName,
                    'State': alarm.StateValue,
                    'StateUpdatedTimestamp': alarm.StateUpdatedTimestamp,
                    'Type': 'Composite'
                });
            });

            if (!listAlarmsResult.NextToken) {
                gotAllAlarms = true;
            } else {
                nextToken = listAlarmsResult.NextToken;
            }
        }

        return alarms;
    }

    var listAllAlarmsPromise = listAllAlarms();

    var listAllAlarmsResult = await listAllAlarmsPromise;

    return {
        statusCode: 200,
        body: JSON.stringify(listAllAlarmsResult)
    };
};

if (process.env.IS_LOCAL) {
    this.handler();
}