name: luna-bridge
version: 0.1.0
description: Luna bridge skill for Hermes
author: convergentaru
license: MIT

inputs:
  - name: luna_token
    description: Luna authentication token
    type: string
    required: true

outputs:
  - name: chatgpt_response
    description: Response from ChatGPT
    type: string
    required: true

actions:
  - name: send_to_chatgpt
    description: Send a message to ChatGPT via Luna bridge
    inputs:
      - name: message
        description: Message to send to ChatGPT
        type: string
        required: true
    outputs:
      - name: response
        description: Response from ChatGPT
        type: string
        required: true

parameters:
  luna_token:
    description: Luna authentication token
    type: string
    required: true

metadata:
  documentation: docs/luna-bridge.md
  tags: luna, chatgpt, bridge
  dependencies:
    - luna
    - chatgpt
  tests:
    - name: test_send_message
      description: Test sending a message to ChatGPT
      inputs:
        message: "Hello, ChatGPT!"
      outputs:
        response: "Hello! How can I assist you today?"
