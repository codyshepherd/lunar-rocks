"""Configures the client with endpoints and Cognito outputs"""

from typing import Dict
import boto3
import click


def write_amplify_config(stack: Dict):
    """Configure the client with Cognito outputs"""
    try:
        config = {}
        for output in stack['Outputs']:
            if output['OutputKey'] == 'UserPoolOutput':
                config['user_pool_id'] = output['OutputValue']

            if output['OutputKey'] == 'UserPoolClientOutput':
                config['user_pool_web_client_id'] = output['OutputValue']

            if output['OutputKey'] == 'IdentityPoolOutput':
                config['identity_pool_id'] = output['OutputValue']

            if output['OutputKey'] == 'UserObjectStoreOutput':
                config['user_object_store_id'] = output['OutputValue']


        # with open('../client/aws/aws-exports.js', 'w') as config_file:
        #     config_file.write(
        #         'export const awsconfig = {\n'
        #         '  region: "us-west-2",\n'
        #         f'  identityPoolId: "{config["identity_pool_id"]}",\n'
        #         f'  userPoolId: "{config["user_pool_id"]}",\n'
        #         f'  userPoolWebClientId: "{config["user_pool_web_client_id"]}"\n'
        #         '};'
        #     )

        with open('../client/aws/aws-exports.js', 'w') as config_file:
            config_file.write(
                'export const awsconfig = {\n'
                '  Auth: {\n'
                f'    identityPoolId: "{config["identity_pool_id"]}",\n'
                '    region: "us-west-2",\n'
                f'    userPoolId: "{config["user_pool_id"]}",\n'
                f'    userPoolWebClientId: "{config["user_pool_web_client_id"]}"\n'
                '  },\n'
                '  Storage: {\n'
                '    AWSS3: {\n'
                f'      bucket: "{config["user_object_store_id"]}",\n'
                '      region: "us-west-2",\n'
                '    }\n'
                '  }\n'
                '};'
            )

    except KeyError as ex:
        print('The stack was not configured properly. A {} key could not be found'.format(ex))

@click.command()
@click.option('-p', '--profile', type=str, default='default',
              help='the aws profile to use')
def start(profile):
    session = boto3.session.Session(profile_name=profile)
    cloudformation = session.client('cloudformation', region_name='us-west-2')
    stacks = cloudformation.describe_stacks(StackName='LunarRocksStack')

    try:
        stack = stacks['Stacks'][0]
        write_amplify_config(stack)

    except KeyError:
        print('Stack does not exist')

if __name__ == '__main__':
    start()
