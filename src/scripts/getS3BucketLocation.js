var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function getS3BucketLocation(bucketName) {
        var s3 = new AWS.S3({
            apiVersion: '2006-03-01'
        });

        var params = {
            Bucket: bucketName
        };

        return s3.getBucketLocation(params).promise();
    }

    const bucketName = helper.getParameter(event, "bucketName");

    if (!bucketName) {
        throw "No function arn passed";
    }

    var getS3BucketLocationPromise = getS3BucketLocation(bucketName);

    var getS3BucketLocationResult = await getS3BucketLocationPromise;

    console.log(getS3BucketLocationResult);

    var result = {
        region: getS3BucketLocationResult.LocationConstraint ? getS3BucketLocationResult.LocationConstraint : us-east-1
    };

    return {
        statusCode: 200,
        body: JSON.stringify(result)
    };
};