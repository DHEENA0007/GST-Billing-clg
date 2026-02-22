"""API views for the AI Engine."""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .ai_engine import AIEngine


class AIAlertsView(APIView):
    """Get all active AI-generated alerts."""
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        engine = AIEngine()
        alerts = engine.get_all_alerts()
        return Response({
            'count': len(alerts),
            'critical': len([a for a in alerts if a['severity'] == 'CRITICAL']),
            'warning': len([a for a in alerts if a['severity'] == 'WARNING']),
            'info': len([a for a in alerts if a['severity'] == 'INFO']),
            'alerts': alerts
        })


class AIRecommendationsView(APIView):
    """Get AI-generated business recommendations."""
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        engine = AIEngine()
        recs = engine.get_recommendations()
        return Response({
            'count': len(recs),
            'recommendations': recs
        })


class AIPredictionsView(APIView):
    """Get AI-generated predictions and forecasts."""
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        engine = AIEngine()
        predictions = engine.get_predictions()
        return Response(predictions)


class AIInsightsView(APIView):
    """Get AI-generated business insights."""
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        engine = AIEngine()
        insights = engine.get_insights()
        return Response(insights)


class AIDashboardView(APIView):
    """Unified AI dashboard endpoint - returns everything."""
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        engine = AIEngine()
        return Response({
            'alerts': engine.get_all_alerts(),
            'recommendations': engine.get_recommendations(),
            'predictions': engine.get_predictions(),
            'insights': engine.get_insights(),
        })
