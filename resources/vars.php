<?php
function main($args) : array {
    return [
        "api_host" => getenv('__OW_API_HOST'),
        "api_key" => getenv('__OW_API_KEY'),
        "namespace" => getenv('__OW_NAMESPACE'),
        "action_name" => getenv('__OW_ACTION_NAME'),
        "activation_id" => getenv('__OW_ACTIVATION_ID'),
        "deadline" => getenv('__OW_DEADLINE'),
      ];
}
?>
