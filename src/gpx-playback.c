/* gpx-playback.c generated by valac 0.28.1, the Vala compiler
 * generated from gpx-playback.vala, do not modify */

/* Gpx Viewer
 * Copyright (C) 2009-2015 Qball Cow <qball@sarine.nl>
 * Project homepage: http://blog.sarine.nl/

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <string.h>
#include <config.h>
#include "gpx.h"
#include <float.h>
#include <math.h>

#define _g_timer_destroy0(var) ((var == NULL) ? NULL : (var = (g_timer_destroy (var), NULL)))
#define _g_object_unref0(var) ((var == NULL) ? NULL : (var = (g_object_unref (var), NULL)))
#define _gpx_point_unref0(var) ((var == NULL) ? NULL : (var = (gpx_point_unref (var), NULL)))

struct _GpxPlaybackPrivate {
	GTimer* progress;
	GpxTrack* track;
	guint timer;
	GList* current;
	GpxPoint* first;
	gint _speedup;
};


static gpointer gpx_playback_parent_class = NULL;

#define GT_LOG_DOMAIN "GPX_PLAYBACK"
#define gt_unique_graph VERSION
#define GPX_PLAYBACK_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), GPX_TYPE_PLAYBACK, GpxPlaybackPrivate))
enum  {
	GPX_PLAYBACK_DUMMY_PROPERTY,
	GPX_PLAYBACK_SPEEDUP
};
static gboolean _gpx_playback_timer_callback_gsource_func (gpointer self);
static void g_cclosure_user_marshal_VOID__GPX_POINT (GClosure * closure, GValue * return_value, guint n_param_values, const GValue * param_values, gpointer invocation_hint, gpointer marshal_data);
static void gpx_playback_finalize (GObject* obj);
static void _vala_gpx_playback_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec);
static void _vala_gpx_playback_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec);


GType gpx_playback_state_get_type (void) {
	static volatile gsize gpx_playback_state_type_id__volatile = 0;
	if (g_once_init_enter (&gpx_playback_state_type_id__volatile)) {
		static const GEnumValue values[] = {{GPX_PLAYBACK_STATE_STOPPED, "GPX_PLAYBACK_STATE_STOPPED", "stopped"}, {GPX_PLAYBACK_STATE_PAUSED, "GPX_PLAYBACK_STATE_PAUSED", "paused"}, {GPX_PLAYBACK_STATE_PLAY, "GPX_PLAYBACK_STATE_PLAY", "play"}, {0, NULL, NULL}};
		GType gpx_playback_state_type_id;
		gpx_playback_state_type_id = g_enum_register_static ("GpxPlaybackState", values);
		g_once_init_leave (&gpx_playback_state_type_id__volatile, gpx_playback_state_type_id);
	}
	return gpx_playback_state_type_id__volatile;
}


static gpointer _g_object_ref0 (gpointer self) {
	return self ? g_object_ref (self) : NULL;
}


static gpointer _gpx_point_ref0 (gpointer self) {
	return self ? gpx_point_ref (self) : NULL;
}


void gpx_playback_set_track (GpxPlayback* self, GpxTrack* track) {
	GpxTrack* _tmp0_ = NULL;
	GpxTrack* _tmp1_ = NULL;
	gboolean _tmp2_ = FALSE;
	GpxTrack* _tmp3_ = NULL;
	g_return_if_fail (self != NULL);
	gpx_playback_stop (self);
	_tmp0_ = track;
	_tmp1_ = _g_object_ref0 (_tmp0_);
	_g_object_unref0 (self->priv->track);
	self->priv->track = _tmp1_;
	_tmp3_ = self->priv->track;
	if (_tmp3_ != NULL) {
		GpxTrack* _tmp4_ = NULL;
		GList* _tmp5_ = NULL;
		_tmp4_ = self->priv->track;
		_tmp5_ = _tmp4_->points;
		_tmp2_ = _tmp5_ != NULL;
	} else {
		_tmp2_ = FALSE;
	}
	if (_tmp2_) {
		GpxTrack* _tmp6_ = NULL;
		GList* _tmp7_ = NULL;
		GList* _tmp8_ = NULL;
		gconstpointer _tmp9_ = NULL;
		GpxPoint* _tmp10_ = NULL;
		_tmp6_ = self->priv->track;
		_tmp7_ = _tmp6_->points;
		_tmp8_ = g_list_first (_tmp7_);
		_tmp9_ = _tmp8_->data;
		_tmp10_ = _gpx_point_ref0 ((GpxPoint*) _tmp9_);
		_gpx_point_unref0 (self->priv->first);
		self->priv->first = _tmp10_;
	}
}


GpxPlayback* gpx_playback_construct (GType object_type, GpxTrack* track) {
	GpxPlayback * self = NULL;
	GpxTrack* _tmp0_ = NULL;
	GpxTrack* _tmp1_ = NULL;
	gboolean _tmp2_ = FALSE;
	GpxTrack* _tmp3_ = NULL;
	self = (GpxPlayback*) g_object_new (object_type, NULL);
	_tmp0_ = track;
	_tmp1_ = _g_object_ref0 (_tmp0_);
	_g_object_unref0 (self->priv->track);
	self->priv->track = _tmp1_;
	_tmp3_ = self->priv->track;
	if (_tmp3_ != NULL) {
		GpxTrack* _tmp4_ = NULL;
		GList* _tmp5_ = NULL;
		_tmp4_ = self->priv->track;
		_tmp5_ = _tmp4_->points;
		_tmp2_ = _tmp5_ != NULL;
	} else {
		_tmp2_ = FALSE;
	}
	if (_tmp2_) {
		GpxTrack* _tmp6_ = NULL;
		GList* _tmp7_ = NULL;
		GList* _tmp8_ = NULL;
		gconstpointer _tmp9_ = NULL;
		GpxPoint* _tmp10_ = NULL;
		_tmp6_ = self->priv->track;
		_tmp7_ = _tmp6_->points;
		_tmp8_ = g_list_first (_tmp7_);
		_tmp9_ = _tmp8_->data;
		_tmp10_ = _gpx_point_ref0 ((GpxPoint*) _tmp9_);
		_gpx_point_unref0 (self->priv->first);
		self->priv->first = _tmp10_;
	}
	return self;
}


GpxPlayback* gpx_playback_new (GpxTrack* track) {
	return gpx_playback_construct (GPX_TYPE_PLAYBACK, track);
}


gboolean gpx_playback_timer_callback (GpxPlayback* self) {
	gboolean result = FALSE;
	GList* _tmp0_ = NULL;
	GList* _tmp3_ = NULL;
	gconstpointer _tmp4_ = NULL;
	time_t _tmp5_ = 0;
	GpxPoint* _tmp6_ = NULL;
	time_t _tmp7_ = 0;
	gint _tmp8_ = 0;
	GTimer* _tmp9_ = NULL;
	gdouble _tmp10_ = 0.0;
	GList* _tmp11_ = NULL;
	gconstpointer _tmp12_ = NULL;
	g_return_val_if_fail (self != NULL, FALSE);
	_tmp0_ = self->priv->current;
	if (_tmp0_ == NULL) {
		GTimer* _tmp1_ = NULL;
		GTimer* _tmp2_ = NULL;
		_tmp1_ = self->priv->progress;
		g_timer_stop (_tmp1_);
		_tmp2_ = self->priv->progress;
		g_timer_reset (_tmp2_);
		g_signal_emit_by_name (self, "state-changed", GPX_PLAYBACK_STATE_STOPPED);
		g_signal_emit_by_name (self, "tick", NULL);
		result = FALSE;
		return result;
	}
	_tmp3_ = self->priv->current;
	_tmp4_ = _tmp3_->data;
	_tmp5_ = gpx_point_get_time ((GpxPoint*) _tmp4_);
	_tmp6_ = self->priv->first;
	_tmp7_ = gpx_point_get_time (_tmp6_);
	_tmp8_ = self->priv->_speedup;
	_tmp9_ = self->priv->progress;
	_tmp10_ = g_timer_elapsed (_tmp9_, NULL);
	if (((gdouble) _tmp5_) > (_tmp7_ + (_tmp8_ * _tmp10_))) {
		result = TRUE;
		return result;
	}
	_tmp11_ = self->priv->current;
	_tmp12_ = _tmp11_->data;
	g_signal_emit_by_name (self, "tick", (GpxPoint*) _tmp12_);
	while (TRUE) {
		gboolean _tmp13_ = FALSE;
		GList* _tmp14_ = NULL;
		GList* _tmp23_ = NULL;
		GList* _tmp24_ = NULL;
		_tmp14_ = self->priv->current;
		if (_tmp14_ != NULL) {
			GList* _tmp15_ = NULL;
			gconstpointer _tmp16_ = NULL;
			time_t _tmp17_ = 0;
			GpxPoint* _tmp18_ = NULL;
			time_t _tmp19_ = 0;
			gint _tmp20_ = 0;
			GTimer* _tmp21_ = NULL;
			gdouble _tmp22_ = 0.0;
			_tmp15_ = self->priv->current;
			_tmp16_ = _tmp15_->data;
			_tmp17_ = gpx_point_get_time ((GpxPoint*) _tmp16_);
			_tmp18_ = self->priv->first;
			_tmp19_ = gpx_point_get_time (_tmp18_);
			_tmp20_ = self->priv->_speedup;
			_tmp21_ = self->priv->progress;
			_tmp22_ = g_timer_elapsed (_tmp21_, NULL);
			_tmp13_ = ((gdouble) _tmp17_) < (_tmp19_ + (_tmp20_ * _tmp22_));
		} else {
			_tmp13_ = FALSE;
		}
		if (!_tmp13_) {
			break;
		}
		_tmp23_ = self->priv->current;
		_tmp24_ = _tmp23_->next;
		self->priv->current = _tmp24_;
	}
	result = TRUE;
	return result;
}


static gboolean _gpx_playback_timer_callback_gsource_func (gpointer self) {
	gboolean result;
	result = gpx_playback_timer_callback ((GpxPlayback*) self);
	return result;
}


void gpx_playback_start (GpxPlayback* self) {
	GpxPoint* _tmp0_ = NULL;
	g_return_if_fail (self != NULL);
	gpx_playback_stop (self);
	_tmp0_ = self->priv->first;
	if (_tmp0_ != NULL) {
		GTimer* _tmp1_ = NULL;
		GpxTrack* _tmp2_ = NULL;
		GList* _tmp3_ = NULL;
		GList* _tmp4_ = NULL;
		guint _tmp5_ = 0U;
		_tmp1_ = self->priv->progress;
		g_timer_start (_tmp1_);
		g_signal_emit_by_name (self, "state-changed", GPX_PLAYBACK_STATE_PLAY);
		g_debug ("gpx-playback.vala:98: start playback\n");
		_tmp2_ = self->priv->track;
		_tmp3_ = _tmp2_->points;
		_tmp4_ = g_list_first (_tmp3_);
		self->priv->current = _tmp4_;
		_tmp5_ = g_timeout_add_full (G_PRIORITY_DEFAULT, (guint) 100, _gpx_playback_timer_callback_gsource_func, g_object_ref (self), g_object_unref);
		self->priv->timer = _tmp5_;
	}
}


void gpx_playback_pause (GpxPlayback* self) {
	GList* _tmp0_ = NULL;
	guint _tmp1_ = 0U;
	g_return_if_fail (self != NULL);
	_tmp0_ = self->priv->current;
	if (_tmp0_ == NULL) {
		return;
	}
	_tmp1_ = self->priv->timer;
	if (_tmp1_ > ((guint) 0)) {
		guint _tmp2_ = 0U;
		GTimer* _tmp3_ = NULL;
		_tmp2_ = self->priv->timer;
		g_source_remove (_tmp2_);
		self->priv->timer = (guint) 0;
		_tmp3_ = self->priv->progress;
		g_timer_stop (_tmp3_);
		g_signal_emit_by_name (self, "state-changed", GPX_PLAYBACK_STATE_PAUSED);
	} else {
		guint _tmp4_ = 0U;
		GTimer* _tmp5_ = NULL;
		_tmp4_ = g_timeout_add_full (G_PRIORITY_DEFAULT, (guint) 250, _gpx_playback_timer_callback_gsource_func, g_object_ref (self), g_object_unref);
		self->priv->timer = _tmp4_;
		_tmp5_ = self->priv->progress;
		g_timer_continue (_tmp5_);
		g_signal_emit_by_name (self, "state-changed", GPX_PLAYBACK_STATE_PLAY);
	}
}


void gpx_playback_stop (GpxPlayback* self) {
	guint _tmp0_ = 0U;
	g_return_if_fail (self != NULL);
	_tmp0_ = self->priv->timer;
	if (_tmp0_ > ((guint) 0)) {
		guint _tmp1_ = 0U;
		GTimer* _tmp2_ = NULL;
		GTimer* _tmp3_ = NULL;
		g_debug ("gpx-playback.vala:120: stop playback\n");
		_tmp1_ = self->priv->timer;
		g_source_remove (_tmp1_);
		self->priv->timer = (guint) 0;
		_tmp2_ = self->priv->progress;
		g_timer_stop (_tmp2_);
		_tmp3_ = self->priv->progress;
		g_timer_reset (_tmp3_);
		g_signal_emit_by_name (self, "state-changed", GPX_PLAYBACK_STATE_STOPPED);
	}
	g_signal_emit_by_name (self, "tick", NULL);
}


gint gpx_playback_get_speedup (GpxPlayback* self) {
	gint result;
	gint _tmp0_ = 0;
	g_return_val_if_fail (self != NULL, 0);
	_tmp0_ = self->priv->_speedup;
	result = _tmp0_;
	return result;
}


void gpx_playback_set_speedup (GpxPlayback* self, gint value) {
	gint _tmp0_ = 0;
	g_return_if_fail (self != NULL);
	gpx_playback_pause (self);
	_tmp0_ = value;
	self->priv->_speedup = _tmp0_;
	gpx_playback_pause (self);
	g_object_notify ((GObject *) self, "speedup");
}


static void g_cclosure_user_marshal_VOID__GPX_POINT (GClosure * closure, GValue * return_value, guint n_param_values, const GValue * param_values, gpointer invocation_hint, gpointer marshal_data) {
	typedef void (*GMarshalFunc_VOID__GPX_POINT) (gpointer data1, gpointer arg_1, gpointer data2);
	register GMarshalFunc_VOID__GPX_POINT callback;
	register GCClosure * cc;
	register gpointer data1;
	register gpointer data2;
	cc = (GCClosure *) closure;
	g_return_if_fail (n_param_values == 2);
	if (G_CCLOSURE_SWAP_DATA (closure)) {
		data1 = closure->data;
		data2 = param_values->data[0].v_pointer;
	} else {
		data1 = param_values->data[0].v_pointer;
		data2 = closure->data;
	}
	callback = (GMarshalFunc_VOID__GPX_POINT) (marshal_data ? marshal_data : cc->callback);
	callback (data1, gpx_value_get_point (param_values + 1), data2);
}


static void gpx_playback_class_init (GpxPlaybackClass * klass) {
	gpx_playback_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (GpxPlaybackPrivate));
	G_OBJECT_CLASS (klass)->get_property = _vala_gpx_playback_get_property;
	G_OBJECT_CLASS (klass)->set_property = _vala_gpx_playback_set_property;
	G_OBJECT_CLASS (klass)->finalize = gpx_playback_finalize;
	g_object_class_install_property (G_OBJECT_CLASS (klass), GPX_PLAYBACK_SPEEDUP, g_param_spec_int ("speedup", "speedup", "speedup", G_MININT, G_MAXINT, 0, G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));
	g_signal_new ("tick", GPX_TYPE_PLAYBACK, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_user_marshal_VOID__GPX_POINT, G_TYPE_NONE, 1, GPX_TYPE_POINT);
	g_signal_new ("state_changed", GPX_TYPE_PLAYBACK, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__ENUM, G_TYPE_NONE, 1, GPX_PLAYBACK_TYPE_STATE);
}


static void gpx_playback_instance_init (GpxPlayback * self) {
	GTimer* _tmp0_ = NULL;
	self->priv = GPX_PLAYBACK_GET_PRIVATE (self);
	_tmp0_ = g_timer_new ();
	self->priv->progress = _tmp0_;
	self->priv->track = NULL;
	self->priv->timer = (guint) 0;
	self->priv->first = NULL;
	self->priv->_speedup = 50;
}


static void gpx_playback_finalize (GObject* obj) {
	GpxPlayback * self;
	self = G_TYPE_CHECK_INSTANCE_CAST (obj, GPX_TYPE_PLAYBACK, GpxPlayback);
	g_debug ("gpx-playback.vala:132: Destroying playback");
	_g_timer_destroy0 (self->priv->progress);
	_g_object_unref0 (self->priv->track);
	_gpx_point_unref0 (self->priv->first);
	G_OBJECT_CLASS (gpx_playback_parent_class)->finalize (obj);
}


GType gpx_playback_get_type (void) {
	static volatile gsize gpx_playback_type_id__volatile = 0;
	if (g_once_init_enter (&gpx_playback_type_id__volatile)) {
		static const GTypeInfo g_define_type_info = { sizeof (GpxPlaybackClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) gpx_playback_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (GpxPlayback), 0, (GInstanceInitFunc) gpx_playback_instance_init, NULL };
		GType gpx_playback_type_id;
		gpx_playback_type_id = g_type_register_static (G_TYPE_OBJECT, "GpxPlayback", &g_define_type_info, 0);
		g_once_init_leave (&gpx_playback_type_id__volatile, gpx_playback_type_id);
	}
	return gpx_playback_type_id__volatile;
}


static void _vala_gpx_playback_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec) {
	GpxPlayback * self;
	self = G_TYPE_CHECK_INSTANCE_CAST (object, GPX_TYPE_PLAYBACK, GpxPlayback);
	switch (property_id) {
		case GPX_PLAYBACK_SPEEDUP:
		g_value_set_int (value, gpx_playback_get_speedup (self));
		break;
		default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;
	}
}


static void _vala_gpx_playback_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec) {
	GpxPlayback * self;
	self = G_TYPE_CHECK_INSTANCE_CAST (object, GPX_TYPE_PLAYBACK, GpxPlayback);
	switch (property_id) {
		case GPX_PLAYBACK_SPEEDUP:
		gpx_playback_set_speedup (self, g_value_get_int (value));
		break;
		default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;
	}
}



