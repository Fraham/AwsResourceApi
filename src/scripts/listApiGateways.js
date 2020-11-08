var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function listApiGateway(nextToken) {
        var apigateway = new AWS.APIGateway({
            apiVersion: '2015-07-09',
            region: process.env.AWS_REGION
        });

        var params = {
            limit: 10
        };

        if (nextToken) {
            params.position = nextToken;
        }

        return apigateway.getRestApis(params).promise();
    }

    async function listAllApiGateways() {
        const gateways = [];
        var nextToken = null;
        var gotAll = false;

        while (!gotAll) {
            var listApiGatewayPromise = listApiGateway(nextToken);

            var listApiGatewayResult = await listApiGatewayPromise;

            listApiGatewayResult.items.forEach(gateway => {
                gateways.push({
                    'Id': gateway.id,
                    'Name': gateway.name
                });
            });

            if (!listApiGatewayResult.position) {
                gotAll = true;
            } else {
                nextToken = listApiGatewayResult.position;
            }
        }

        return gateways;
    }

    var listAllApiGatewaysPromise = listAllApiGateways();

    var listAllApiGatewaysResult = await listAllApiGatewaysPromise;

    console.log(listAllApiGatewaysResult);

    return {
        statusCode: 200,
        body: JSON.stringify(listAllApiGatewaysResult)
    };
};
if (process.env.IS_LOCAL) {
    this.handler();
}