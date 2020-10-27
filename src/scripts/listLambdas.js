var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

exports.handler = async (event) => {

    async function listFunctions(nextToken) {
        var lambda = new AWS.Lambda({
            apiVersion: '2015-03-31',
            region: process.env.AWS_REGION
        });

        var params = {
            MaxItems: 10
        };

        if (nextToken) {
            params.Marker = nextToken;
        }

        return lambda.listFunctions(params).promise();
    }

    async function listAllFunctions() {
        const functions = [];
        var nextToken = null;
        var gotAllFunctions = false;

        while (!gotAllFunctions) {
            var listFunctionsPromise = listFunctions(nextToken);

            var listFunctionsResult = await listFunctionsPromise;

            listFunctionsResult.Functions.forEach(lambda => {
                functions.push({
                    'ARN': lambda.FunctionArn,
                    'Name': lambda.FunctionName
                });
            });

            if (!listFunctionsResult.NextMarker) {
                gotAllFunctions = true;
            } else {
                nextToken = listFunctionsResult.NextMarker;
            }
        }

        return functions;
    }

    var listAllFunctionsPromise = listAllFunctions();

    var listAllFunctionsResult = await listAllFunctionsPromise;

    return {
        statusCode: 200,
        body: JSON.stringify(listAllFunctionsResult)
    };
};
