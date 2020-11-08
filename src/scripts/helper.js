var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}


module.exports = {
    parseJsonString: function (jsonString) {
        if (typeof jsonString === 'string') {
            jsonString = JSON.parse(jsonString);
        }

        return jsonString;
    },
    getSecret: async function (secretName) {

        var client = new AWS.SecretsManager({
            region: process.env.AWS_REGION
        });

        return new Promise((resolve, reject) => {
            client.getSecretValue({ SecretId: secretName }, (err, data) => {
                if (err) {
                    console.error(err);
                    reject(err);
                    return;
                }

                var secret = "NotSet";

                if ('SecretString' in data) {
                    secret = data.SecretString;
                }
                else {
                    let buff = new Buffer(data.SecretBinary, 'base64');
                    secret = buff.toString('ascii');
                }

                if (secret === "NotSet") {
                    reject(`${secretName} not set in Secrets Manager. The default needs to be overwritten`);
                    return;
                }

                resolve(secret);
            });
        });
    },
    parseSnsMessage: function (record) {
        if (!record.Sns) {
            throw "Unable to find SNS data";
        }

        let sns = this.parseJsonString(record.Sns);

        if (!sns.Message) {
            throw "Unable to find SNS message data";
        }

        return this.parseJsonString(sns.Message);
    },
    checkRecordsInSns: function (event) {
        if (!event || !event.Records || event.Records.length == 0) {
            throw "No event records passed";
        }
    },
    sendMessagesToSns: function (messages, subject, topicArn, context) {
        if (!messages || messages.length == 0) {
            return;
        }

        let fullMessage = {
            "messages": messages
        };

        var snsPublish = new AWS.SNS();
        var params = {
            Message: JSON.stringify(fullMessage),
            Subject: subject,
            TopicArn: topicArn
        };
        snsPublish.publish(params, context.done);
    },
    getParameter(event, parameterName) {
      
        if (event) {
            if (event.body) {
                let body = helper.parseJsonString(event.body);
    
                if (body[parameterName]) {
                    return body[parameterName];
                }
            }
    
            if (event[parameterName]) {
                return event[parameterName];
            }
            
            if (event.pathParameters && event.pathParameters[parameterName]){
                return event.pathParameters[parameterName];
            }
        }

        var parameter = this.getParameter(event, parameterName.toLowerCase());

        if (parameter){
            return parameter;
        }

        return this.getParameter(event, parameterName.toUpperCase());
    }
};