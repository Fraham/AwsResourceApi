var AWS = null;

if (process.env.IS_LOCAL) {
    AWS = require('aws-sdk');
} else {
    const AWSXRay = require('aws-xray-sdk');
    AWS = AWSXRay.captureAWS(require('aws-sdk'));
}

var helper = require('./helper');

exports.handler = async (event) => {

    async function listApiGatewayResource(restApiId, nextToken) {
        var apigateway = new AWS.APIGateway({
            apiVersion: '2015-07-09',
            region: process.env.AWS_REGION
        });

        var params = {
            restApiId: restApiId,
            limit: 1
        };

        if (nextToken) {
            params.position = nextToken;
        }

        return apigateway.getResources(params).promise();
    }

    async function listAllApiGatewayResources(restApiId) {
        const resources = [];
        var nextToken = null;
        var gotAll = false;

        while (!gotAll) {
            var listApiGatewayResourcePromise = listApiGatewayResource(restApiId, nextToken);

            var listApiGatewayResourceResult = await listApiGatewayResourcePromise;

            listApiGatewayResourceResult.items.forEach(resource => {
                console.log(resource);
                resources.push({
                    'Id': resource.id,
                    'ParentId ': resource.parentId,
                    'PathPart': resource.pathPart
                });
            });

            if (!listApiGatewayResourceResult.position) {
                gotAll = true;
            } else {
                nextToken = listApiGatewayResourceResult.position;
            }
        }

        return resources;
    }

    const restApiId = helper.getParameter(event, "restApiId");

    var listAllApiGatewaysPromisResourcee = listAllApiGatewayResources(restApiId);

    var listAllApiGatewaysResulResourcet = await listAllApiGatewaysPromisResourcee;

    console.log(listAllApiGatewaysResulResourcet);

    return {
        statusCode: 200,
        body: JSON.stringify(listAllApiGatewaysResulResourcet)
    };
};