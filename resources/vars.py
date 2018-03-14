import os

def main(dict):
    return {
       "api_host": os.environ['__OW_API_HOST'],
       "api_key": os.environ['__OW_API_KEY'],
       "namespace": os.environ['__OW_NAMESPACE'],
       "action_name": os.environ['__OW_ACTION_NAME'],
       "activation_id": os.environ['__OW_ACTIVATION_ID'],
       "deadline": os.environ['__OW_DEADLINE']
    }
