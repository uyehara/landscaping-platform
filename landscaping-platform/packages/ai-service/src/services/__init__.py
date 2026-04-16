from typing import Optional
from openai import OpenAI
from anthropic import Anthropic


class LLMService:
    """LLM orchestration service supporting multiple providers."""

    def __init__(self, openai_key: Optional[str] = None, anthropic_key: Optional[str] = None):
        self.openai_client = OpenAI(api_key=openai_key) if openai_key else None
        self.anthropic_client = Anthropic(api_key=anthropic_key) if anthropic_key else None

    async def chat(self, messages: list[dict], model: str = "gpt-4o-mini", **kwargs):
        """Send chat request to LLM provider."""
        if model.startswith("gpt"):
            if not self.openai_client:
                raise ValueError("OpenAI API key not configured")
            response = self.openai_client.chat.completions.create(
                model=model,
                messages=messages,
                **kwargs
            )
            return response.choices[0].message
        elif model.startswith("claude"):
            if not self.anthropic_client:
                raise ValueError("Anthropic API key not configured")
            response = self.anthropic_client.messages.create(
                model=model,
                messages=messages,
                **kwargs
            )
            return response.content[0].text
        else:
            raise ValueError(f"Unsupported model: {model}")
