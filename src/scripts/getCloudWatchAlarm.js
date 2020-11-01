var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

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

    async function getAlarm(alarmArn) {
        const alarms = [];
        var nextToken = null;
        var gotAllAlarms = false;

        while (!gotAllAlarms && alarms.length === 0) {
            var listAlarmsPromise = listAlarms(nextToken);

            var listAlarmsResult = await listAlarmsPromise;

            if (!listAlarmsResult) {
                continue;
            }

            const alarmarn = alarmArn;

            listAlarmsResult.MetricAlarms.forEach(metricAlarm => {                
                if (metricAlarm.AlarmArn === alarmarn) {
                    alarms.push(metricAlarm);
                }
            });

            listAlarmsResult.CompositeAlarms.forEach(compositeAlarm => {
                if (compositeAlarm.AlarmArn === alarmarn) {
                    alarms.push(compositeAlarm);
                }
            });

            if (!listAlarmsResult.NextToken) {
                gotAllAlarms = true;
            } else {
                nextToken = listAlarmsResult.NextToken;
            }
        }

        if (alarms.length === 1){
            return alarms[0];
        }

        return null;
    }
    var alarmArn = null;

    if (event) {

        if (event.body) {
            let body = helper.parseJsonString(event.body);

            if (body.functionArn) {
                alarmArn = body.functionArn;
            }
        }

        if (event.functionArn) {
            alarmArn = event.functionArn;
        }

        if (event.pathParameters && event.pathParameters.alarmarn) {
            alarmArn = event.pathParameters.alarmarn;
        }
    }

    if (!alarmArn) {
        throw "No alarm arn passed";
    }

    var getAlarmPromise = getAlarm(alarmArn);

    var getAlarmResult = await getAlarmPromise;

    if (!getAlarmResult) {
        throw "Alarm not found";
    }

    return {
        statusCode: 200,
        body: JSON.stringify(getAlarmResult)
    };
};