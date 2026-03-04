package com.dedxab.spendly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class QuickAddWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)
            views.setOnClickPendingIntent(
                R.id.btn_add_expense,
                createQuickAddPendingIntent(
                    context = context,
                    requestCode = widgetId * 10 + 1,
                    type = "expense",
                ),
            )
            views.setOnClickPendingIntent(
                R.id.btn_add_income,
                createQuickAddPendingIntent(
                    context = context,
                    requestCode = widgetId * 10 + 2,
                    type = "income",
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun createQuickAddPendingIntent(
        context: Context,
        requestCode: Int,
        type: String,
    ): PendingIntent {
        val deepLink = Uri.parse("spendly://app/transactions/new?type=$type")
        val intent = Intent(Intent.ACTION_VIEW, deepLink, context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
