"""Gemini AI コーチング生成サービス - GeminiCoachingService"""

import json
import logging
from typing import Dict, Optional

from app.models import WeeklyCoachingData

logger = logging.getLogger(__name__)


class CoachingMessage:
    """コーチングメッセージを表すデータクラス"""

    def __init__(
        self,
        highlight: str,
        advice: str,
        parent_tip: str,
    ):
        self.highlight = highlight
        self.advice = advice
        self.parent_tip = parent_tip

    def to_dict(self) -> Dict:
        return {
            "highlight": self.highlight,
            "advice": self.advice,
            "parent_tip": self.parent_tip,
        }


class GeminiCoachingService:
    """
    Vertex AI (Gemini) を使用して、親向けコーチングメッセージを生成
    """

    def __init__(
        self,
        project_id: str,
        location: str = "asia-northeast1",
        model_id: str = "gemini-1.5-flash",
    ):
        self.project_id = project_id
        self.location = location
        self.model_id = model_id

        # Vertex AI を初期化 (lazy import to avoid dependency issues in tests)
        try:
            from google.cloud import aiplatform
            from vertexai.generative_models import GenerativeModel

            aiplatform.init(project=project_id, location=location)
            self.model = GenerativeModel(model_id)
        except ImportError as e:
            logger.warning(f"Vertex AI dependencies not available: {e}")
            self.model = None

    async def generate_coaching_message(
        self,
        coaching_data: WeeklyCoachingData,
        child_name: str,
        child_grade: int,
    ) -> CoachingMessage:
        """
        週次分析データに基づいてAI生成コーチングメッセージを生成

        Args:
            coaching_data: 週次分析データ
            child_name: 子の名前
            child_grade: 子の学年

        Returns:
            CoachingMessage: コーチングメッセージ（highlight, advice, parent_tip）
        """

        # Vertex AI が利用できない場合
        if self.model is None:
            logger.warning("Vertex AI model not available, returning default coaching message")
            return CoachingMessage(
                highlight="この週も頑張りました！",
                advice=f"{coaching_data.weakest_virtue or '新しい徳目'}を学ぶストーリーがお勧めです。",
                parent_tip="お子様の成長をサポートいただきありがとうございます。",
            )

        # プロンプトを構築
        prompt = self._build_prompt(coaching_data, child_name, child_grade)

        try:
            # Gemini API を呼び出し
            response = self.model.generate_content(prompt)

            # JSON レスポンスをパース
            response_text = response.text.strip()

            # マークダウンのコードブロックを削除（```json ... ```）
            if response_text.startswith("```"):
                response_text = response_text.split("```")[1]
                if response_text.startswith("json"):
                    response_text = response_text[4:]
                response_text = response_text.strip()
            if response_text.endswith("```"):
                response_text = response_text[:-3]

            response_json = json.loads(response_text)

            # CoachingMessage を構築
            coaching_message = CoachingMessage(
                highlight=response_json.get("highlight", "頑張りました！"),
                advice=response_json.get("advice", "来週も応援しています！"),
                parent_tip=response_json.get(
                    "parent_tip", "お子様の成長をお祈りします。"
                ),
            )

            return coaching_message

        except Exception as e:
            logger.error(f"Gemini コーチング生成エラー: {e}")
            # フォールバック: デフォルトメッセージを返す
            return CoachingMessage(
                highlight="この週も頑張りました！",
                advice=f"{coaching_data.weakest_virtue or '新しい徳目'}を学ぶストーリーがお勧めです。",
                parent_tip="お子様の成長をサポートいただきありがとうございます。",
            )

    def _build_prompt(
        self,
        coaching_data: WeeklyCoachingData,
        child_name: str,
        child_grade: int,
    ) -> str:
        """
        Gemini 用のプロンプトを構築
        """

        virtue_changes_text = "\n".join(
            [
                f"  - {virtue}: {change:+d}ポイント"
                for virtue, change in (coaching_data.virtue_score_changes or {}).items()
            ]
        )

        prompt = f"""あなたは小学校の道徳教育の専門家で、親向けのAIコーチングアシスタントです。
以下の子どもの週間学習データに基づいて、親向けのポジティブで励ましのメッセージを生成してください。

【子どもの情報】
- 名前: {child_name}
- 学年: {child_grade}年生

【この週の学習成績】
- 完了ストーリー数: {coaching_data.weekly_stories_completed}個
- 学習時間: {coaching_data.weekly_study_minutes}分
- 獲得ポイント: {coaching_data.weekly_points_earned}ポイント
- 最も成長した徳目: {coaching_data.strongest_virtue or "未評価"}
- 最も改善が必要な徳目: {coaching_data.weakest_virtue or "未評価"}
- 徳目スコア変化:
{virtue_changes_text or "  デーション なし"}
- 連続完了日数: {coaching_data.completion_streak}日
- 前週との比較: {coaching_data.trend_analysis or "初週のため未評価"}

【出力フォーマット】
以下のJSON形式で、3つのメッセージを生成してください。
各メッセージは 30-50文字程度の簡潔で励ましのある内容にしてください。

{{
  "highlight": "🌟 この週の{child_name}の成長ポイント（30-50文字、子の頑張りを褒める内容）",
  "advice": "💡 来週へのアドバイス（30-50文字、{coaching_data.weakest_virtue or '新しい徳目'}を含めたお勧めストーリーを示唆）",
  "parent_tip": "👨‍👩‍👧 保護者へのメッセージ（30-50文字、励ましと褒める内容）"
}}

【トーン】
- 親に対して常にポジティブで励ましのあるトーン
- 子の成長を認め、親の努力をサポート
- 来週への期待感を高める
- 日本語で親しみやすく、敬体で作成

【重要】
- JSON形式でのみ返答してください
- マークダウンのコードブロック（```）で囲まなくても構いません
- 3つのキーすべてが存在する必要があります
"""

        return prompt
