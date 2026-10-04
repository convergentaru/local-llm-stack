from litellm.integrations.custom_logger import CustomLogger


def _content_to_text(content):
    if isinstance(content, str):
        return content

    if isinstance(content, list):
        parts = []

        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    parts.append(str(item.get("text", "")))
                elif "text" in item:
                    parts.append(str(item["text"]))
            elif isinstance(item, str):
                parts.append(item)

        return "\n".join(p for p in parts if p)

    if content is None:
        return ""

    return str(content)


class QwenMessageNormalizer(CustomLogger):
    async def async_pre_call_hook(
        self,
        user_api_key_dict,
        cache,
        data: dict,
        call_type,
        **kwargs,
    ):
        messages = data.get("messages")

        if not isinstance(messages, list) or not messages:
            return data

        # Only normalize requests going to the local Qwen alias.
        model = data.get("model", "")
        if model not in {"qwen3.5-4b", "claude-sonnet-5"}:
            return data

        system_messages = []
        other_messages = []

        for message in messages:
            if not isinstance(message, dict):
                other_messages.append(message)
                continue

            role = message.get("role")

            if role in {"system", "developer"}:
                system_messages.append(message)
            else:
                other_messages.append(message)

        if not system_messages:
            return data

        # Merge all system/developer messages into ONE system message.
        merged_parts = []

        for message in system_messages:
            text = _content_to_text(message.get("content"))
            if text:
                merged_parts.append(text)

        normalized = {
            "role": "system",
            "content": "\n\n".join(merged_parts),
        }

        data["messages"] = [normalized] + other_messages

        return data


proxy_handler_instance = QwenMessageNormalizer()
