var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function getS3BucketTagging(bucketName) {
        var s3 = new AWS.S3({
            apiVersion: '2006-03-01'
        });

        var params = {
            Bucket: bucketName
        };

        return s3.getBucketTagging(params).promise();
    }

    const bucketName = helper.getParameter(event, "bucketName");

    if (!bucketName) {
        throw "No function arn passed";
    }

    var getS3BucketTaggingPromise = getS3BucketTagging(bucketName);

    var getS3BucketTaggingResult = await getS3BucketTaggingPromise;

    console.log(getS3BucketTaggingResult);

    var results = {
        Tags: { }
    };

    getS3BucketTaggingResult.TagSet.forEach(element => {
        results.Tags[element.Key] = element.Value;
    });

    return {
        statusCode: 200,
        body: JSON.stringify(results)
    };
};