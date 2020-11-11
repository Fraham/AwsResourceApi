var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function listS3Buckets() {
        var s3 = new AWS.S3({
            apiVersion: '2006-03-01'
        });

        var params = {

        };

        return s3.listBuckets(params).promise();
    }

    var listS3BucketsPromise = listS3Buckets();

    var listS3BucketsResult = await listS3BucketsPromise;

    console.log(listS3BucketsResult);

    return {
        statusCode: 200,
        body: JSON.stringify(listS3BucketsResult)
    };
};

if (process.env.IS_LOCAL) {
    this.handler();
}