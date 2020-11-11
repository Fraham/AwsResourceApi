var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function getS3BucketLogging(bucketName) {
        var s3 = new AWS.S3({
            apiVersion: '2006-03-01'
        });

        var params = {
            Bucket: bucketName
        };

        return s3.getBucketLogging(params).promise();
    }

    const bucketName = helper.getParameter(event, "bucketName");

    if (!bucketName) {
        throw "No function arn passed";
    }

    var getS3BucketLoggingPromise = getS3BucketLogging(bucketName);

    var getS3BucketLoggingResult = await getS3BucketLoggingPromise;

    console.log(getS3BucketLoggingResult);

    return {
        statusCode: 200,
        body: JSON.stringify(getS3BucketLoggingResult)
    };
};