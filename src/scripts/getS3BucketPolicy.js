var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function getS3BucketPolicy(bucketName) {
        var s3 = new AWS.S3({
            apiVersion: '2006-03-01'
        });

        var params = {
            Bucket: bucketName
        };

        return s3.getBucketPolicy(params).promise();
    }

    const bucketName = helper.getParameter(event, "bucketName");

    if (!bucketName) {
        throw "No function arn passed";
    }

    var getS3BucketPolicyPromise = getS3BucketPolicy(bucketName);

    var getS3BucketPolicyResult = await getS3BucketPolicyPromise;

    console.log(getS3BucketPolicyResult);

    return {
        statusCode: 200,
        body: JSON.stringify(getS3BucketPolicyResult)
    };
};