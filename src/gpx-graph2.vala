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

using Gtk;
using Gdk;
using Gpx;
using Gpx.Viewer;
using GLib;
using Config;
using Gee;

static const string LOG_DOMAIN="GPX_GRAPH";
static const string unique_graph = Config.VERSION;

namespace Gpx
{
	public struct 2DPoint {
		public double x;
		public double y;
	}	
	public struct graph_sizes_t {
		public double alloc_width;
		public double alloc_height;
		public double graph_width;
		public double graph_height;
		public double start_x;
		public double end_x;
		public double start_y;
		public double end_y;
	}


	public class Graph2View: Gtk.EventBox
	{	
		public class Data {
			public Gee.ArrayList<2DPoint?> points = new Gee.ArrayList<2DPoint?>();
			public 2DPoint max = 2DPoint();
			public 2DPoint min = 2DPoint();
			
			// Axis position: -1 = first on left, -2 second on left .. 1 first right etc.
			public int axis_position = -1;

			public struct style_t {
				public Gdk.RGBA color;
				public Gdk.RGBA? fill;
				public double line_width;
			}

			public style_t style = style_t() {color = {0, 0, 0, 1}, fill = null, line_width = 1	};

			public Data(Gee.ArrayList<2DPoint?> data, int axis_position, Gdk.RGBA color = {0, 0, 0, 1}, Gdk.RGBA? fill = null) {
				this.points = data;
				this.axis_position = axis_position;
				this.style.color = color;
				this.style.fill = fill;
				if(fill != null) {
					stdout.printf("FILLEDDDDDDDd");
				}
				this.find_min_max();
			}
			// From stackoverflow: http://stackoverflow.com/questions/3407012/c-rounding-up-to-the-nearest-multiple-of-a-number (Mark Ransom)
			double round_to_multiple(double num_to_round, int multiple, bool negative = false) 
			{
				int num = (int) Math.ceil(num_to_round);
				if(negative) num -= multiple;
				if(multiple == 0) 
				{ 
					return num_to_round; 
				} 

				int remainder = num % multiple;
				if (remainder == 0)
					return (double) num;
				return (double) num + multiple - remainder;
			}

			private void find_min_max() {
				2DPoint min = {10000.0, 10000.0};
				2DPoint max = {-10000.0, -10000.0};
				foreach(2DPoint p in this.points)
				{
					min.x = (p.x < min.x) ? p.x : min.x;
					min.y = (p.y < min.y) ? p.y : min.y;
					max.x = (p.x > max.x) ? p.x : max.x;
					max.y = (p.y > max.y) ? p.y : max.y;
				}

				min.y = round_to_multiple(min.y, 10, true);
				max.y = round_to_multiple(max.y, 10);

				this.min = min;
				this.max = max;
			}

		}

		private Pango.FontDescription fd = null;
		private Cairo.Surface surf = null;
		// add 0.5 to make the lines non-fuzzy
		private double OFFSET_LEFT = 150.5;
		private double OFFSET_BOTTOM = 30.5;
		private double OFFSET_TOP = 30.5;
		private double OFFSET_RIGHT = 50.5;
		private int highlight = -1;

		private Gdk.RGBA GRID_STRONG;
		private Gdk.RGBA GRID_LIGHT;
		private Gdk.RGBA BACKGROUND;
		private Gdk.RGBA BACKDROP;
		private Gdk.RGBA X_AXIS_COLOR;

		private int AXIS_MARGIN = 50;

		public Gee.ArrayList<Data> _data = new Gee.ArrayList<Data>();

		public bool add_data(Gee.ArrayList<2DPoint?> data, int axis_position, Gdk.RGBA color = {0, 0, 0, 1}, Gdk.RGBA? fill = null) {
			this._data.add(new Data(data, axis_position, color, fill));
			return true;
		}

		public void plot() {
			this.surf = null;
			this.queue_draw();
		}

		public Graph2View ()
		{
			/* Create and setup font description */
			this.fd = new Pango.FontDescription();
			fd.set_family("Cantarell sans mono");

			/* make the event box paintable and give it an own window to paint on */
			this.app_paintable = true;
			this.visible_window = true;

			/* signals */
			this.size_allocate.connect(size_allocate_cb);
			this.button_press_event.connect(button_press_event_cb);

			this.add_events(Gdk.EventMask.POINTER_MOTION_MASK);
			this.motion_notify_event.connect(motion_notify_event_cb);

			this.button_release_event.connect(button_release_event_cb);


			// Set colors (structs can't be initialized in class?)
			GRID_STRONG	= {0.9, 0.9, 0.9, 1};
			GRID_LIGHT	= {0.95, 0.95, 0.95, 1};
			BACKGROUND	= {0.999, 0.999, 0.999, 1};
			BACKDROP	= {0.7, 0.7, 0.7, 1};
			X_AXIS_COLOR = {0, 0, 0, 1};

			this.draw.connect(expose_cb);
		}

		private int? index_from_x(double x) {
			if(this._data.is_empty) return -1;
			var d = _data.first();
			var s = d.points.size;

			var gs = this.get_graph_sizes();
			if(x < gs.start_x || x > gs.end_x) return -1;

			int idx = 0;
			// TODO need to make this faster?
			var search_x = ((x - gs.start_x) / gs.graph_width) * (d.max.x - d.min.x);
			foreach(var p in d.points) {
				if(p.x >= search_x) return idx;
				idx += 1;
			}
			return -1;
			if(idx == s) return s - 1;
			// outside of bounds
			if(idx > s || idx < 0) return -1;
			return idx;
		}
		
		private bool button_release_event_cb(Gdk.EventButton event)
		{
			return true;
		}

		private bool button_press_event_cb(Gdk.EventButton event)
		{
			return true;
		}

		private bool motion_notify_event_cb(Gdk.EventMotion event)
		{
			// if(!this.highlight) {
				// show info about current point!

			// }

			this.highlight = index_from_x(event.x);
			this.plot();
			return true;
		}

		private void size_allocate_cb(Gtk.Allocation alloc)
		{
			/* Invalidate the previous plot, so it is redrawn */
			this.surf = null;
		}

		private void update_surface(Gtk.Widget win)
		{
			var ctx = Gdk.cairo_create(win.get_window());
			log(LOG_DOMAIN, LogLevelFlags.LEVEL_DEBUG, "Updating surface");

			/* Get allocation */
			Gtk.Allocation alloc;
			win.get_allocation(out alloc);
			
			/* Create new surface */
			this.surf = new Cairo.Surface.similar(ctx.get_target(),
					Cairo.Content.COLOR_ALPHA,
					alloc.width, alloc.height);

			ctx = new Cairo.Context(this.surf);

			/* Paint background white */
			ctx.set_source_rgba(1, 1, 1, 1);
			ctx.paint();

			var gs = this.get_graph_sizes();
			// if(graph_height < 50 ) return;
			var layout = Pango.cairo_create_layout(ctx);

			// /* Draw the graph */
			foreach (var d in this._data)
			{
				Gdk.cairo_set_source_rgba(ctx, d.style.color);
				ctx.set_line_width(d.style.line_width);

				ctx.move_to(gs.start_x, gs.start_y);
				foreach (2DPoint p in d.points) {
					var x = gs.start_x + ((p.x - d.min.x) / (d.max.x - d.min.x)) * gs.graph_width;
					var y = gs.start_y - ((p.y - d.min.y) / (d.max.y - d.min.y)) * gs.graph_height;
					ctx.line_to(x, y);
				}

				// draw line to bottom in case of filling
				if(d.style.fill != null) {
					ctx.stroke_preserve();
					ctx.line_to(gs.end_x, gs.start_y);
					Gdk.cairo_set_source_rgba(ctx, d.style.fill);
					ctx.fill();
				} else {
					ctx.stroke();
				}
			}
			draw_axis(ctx, layout, alloc);
			draw_highlight(ctx, layout, alloc);
		}

		void draw_highlight(Cairo.Context ctx, Pango.Layout layout, Gtk.Allocation alloc) {
			if(this.highlight < 0)	return;
			if(this._data.is_empty) return;
			var df = _data.first();
			var gs = get_graph_sizes();
			var x = gs.start_x + ((df.points[highlight].x - df.min.x) / (df.max.x - df.min.x)) * gs.graph_width;
			ctx.set_source_rgba(1, 0, 0, 1);

			ctx.move_to(x, gs.start_y);
			ctx.line_to(x, gs.end_y);
			ctx.stroke();

			fd.set_absolute_size(9*1024);
			layout.set_font_description(fd);

			foreach(var d in _data) {
				var y = gs.start_y - ((d.points[highlight].y - d.min.y) / (d.max.y - d.min.y)) * gs.graph_height;
				print("hi: %i, %f\n", highlight, d.points[highlight].y);
				Gdk.cairo_set_source_rgba(ctx, d.style.color);
				// draw following squares
				ctx.rectangle(x - 2, y - 2, 4, 4);
				ctx.stroke();

				// draw arrows and number on axis
				double at_x = 0;

				if(d.axis_position > 0) {
					at_x = gs.end_x + (d.axis_position - 1) * AXIS_MARGIN;
				} else {
					at_x = gs.start_x + (d.axis_position + 1) * AXIS_MARGIN;
					ctx.move_to(at_x, y);
					ctx.line_to(at_x - 8, y - 8);
					ctx.line_to(at_x - 8, y + 8);
					ctx.fill();
					int w, h;


					var unit = d.points[highlight].y;
					var markup = _("<b>%.1f</b>").printf(unit);
					layout.set_markup(markup, -1);
					layout.get_pixel_size(out w, out h);
					var width = w > 30 ? w + 5 : 30;
					ctx.rectangle(at_x - 8 - width, y - 8, width, 16);
					ctx.fill();

					ctx.set_source_rgba(1, 1, 1, 1);

					ctx.move_to(at_x - width - 3.5, y - h / 2 + 0.5);

					Pango.cairo_layout_path(ctx, layout);
					ctx.fill();
				}


			}
		}

		graph_sizes_t get_graph_sizes() {
			// TODO implement caching...
			Gtk.Allocation alloc;
			this.get_allocation(out alloc);
			graph_sizes_t ret_val = graph_sizes_t();

			ret_val.alloc_width = alloc.width;
			ret_val.alloc_height = alloc.height;

			ret_val.graph_width = ret_val.alloc_width - OFFSET_LEFT - OFFSET_RIGHT;
			ret_val.graph_height = ret_val.alloc_height - OFFSET_TOP - OFFSET_BOTTOM;

			ret_val.start_x = OFFSET_LEFT;
			ret_val.end_x = ret_val.graph_width + OFFSET_LEFT;

			ret_val.start_y = ret_val.alloc_height - OFFSET_BOTTOM;
			ret_val.end_y = OFFSET_TOP;

			return ret_val;
		}

		void draw_axis(Cairo.Context ctx, Pango.Layout layout, Gtk.Allocation alloc) {
			// we assume that all data has the same x axis, so just take the first data
			if(this._data.is_empty) return;
			var d = this._data.first();

			var xmax = d.max.x;
			var xmin = d.max.y;

			var gs = this.get_graph_sizes();

			// X Axis and vertical grid lines
			// black axis
			Gdk.cairo_set_source_rgba(ctx, X_AXIS_COLOR);

			// draw horizontal line
			ctx.move_to(gs.start_x, gs.start_y);
			ctx.line_to(gs.end_x, gs.start_y);
			ctx.stroke();


			var steps = 16.0f;
			int idx = 1;
			int x_stepsize = (int) (gs.graph_width / steps);

			for(var x_dash = gs.start_x + x_stepsize; x_dash <= gs.end_x; x_dash += x_stepsize) {
				if(idx % 2 == 0) Gdk.cairo_set_source_rgba(ctx, GRID_LIGHT);
				else Gdk.cairo_set_source_rgba(ctx, GRID_STRONG);
				ctx.move_to(x_dash, gs.start_y + 5);
				ctx.line_to(x_dash, gs.start_y);
				idx += 1;
			}
			ctx.stroke();

			ctx.set_source_rgba(0, 0, 0, 0.5);
			for(var x_dash = gs.start_x + x_stepsize; x_dash <= gs.end_x; x_dash += x_stepsize) {
				ctx.move_to(x_dash, gs.start_y);
				ctx.line_to(x_dash, gs.end_y);
			}
			ctx.stroke();

			// drawing the tick text
			fd.set_absolute_size(9*1024);
			layout.set_font_description(fd);
			idx = 1;
			for(var x_dash = gs.start_x + x_stepsize; x_dash <= gs.end_x; x_dash += x_stepsize) {
				int w, h;

				var unit = d.points[(int) Math.floor(d.points.size * (idx / steps)) - 1].x;
				var markup = _("%.1f").printf(unit);
				layout.set_markup(markup,-1);

				layout.get_pixel_size(out w, out h);
				ctx.move_to(x_dash -w/2, gs.start_y + 12);
				Pango.cairo_layout_path(ctx, layout);
				ctx.fill();
				idx += 1;
			}

			// Y Axis (note that this is multiple axis, for each data set)
			var y_stepsize = gs.graph_height / 7;
			foreach(var dy in this._data) {
				// Draw in data set color
				Gdk.cairo_set_source_rgba(ctx, dy.style.color);
				double at_x = 0;

				if(dy.axis_position > 0) {
					at_x = gs.end_x + (dy.axis_position - 1) * AXIS_MARGIN;
				} else {
					at_x = gs.start_x + (dy.axis_position + 1) * AXIS_MARGIN;
				}
				ctx.move_to(at_x, gs.start_y);
				// Vertical line
				ctx.line_to(at_x, gs.end_y);
				int stroke_dir = dy.axis_position > 0 ? 5 : -5;
				for(var y_dash = gs.start_y; y_dash > gs.end_y; y_dash -= y_stepsize) {
					ctx.move_to(at_x + stroke_dir, y_dash);
					ctx.line_to(at_x, y_dash);
				}
				ctx.stroke();

				idx = 0;
				for(var y_dash = gs.start_y; y_dash > gs.end_y; y_dash -= y_stepsize) {
					int w, h;
					var unit = dy.min.y + (dy.max.y - dy.min.y) * (idx / 7.0f);
					var markup = _("%.1f").printf(unit);
					layout.set_markup(markup,-1);
					layout.get_pixel_size(out w, out h);

					if(dy.axis_position > 0) // dash direction
						ctx.move_to(at_x + 8, y_dash - h / 2);
					else
						ctx.move_to(at_x - w - 8, y_dash - h / 2);

					Pango.cairo_layout_path(ctx, layout);
					ctx.fill();
					idx += 1;
				}
			}

			ctx.set_source_rgba(0, 0, 0, 0.5);
			for(var y_dash = gs.start_y - y_stepsize; y_dash > gs.end_y; y_dash -= y_stepsize) {
				ctx.move_to(gs.start_x, y_dash);
				ctx.line_to(gs.end_x, y_dash);
			}
			ctx.stroke();
		}

		bool expose_cb(Cairo.Context ctx)
		{
			//var ctx = Gdk.cairo_create(this.get_window());
			/* If no valid surface, render it */
			if(surf == null)
				update_surface(this);

			/* Get allocation */
			Gtk.Allocation alloc;
			this.get_allocation(out alloc);
			// Draw the actual surface on the widget
			ctx.set_source_surface(this.surf, 0, 0);
			ctx.paint();

			// ctx.translate(LEFT_OFFSET,20);
			/* Draw selection, if available */
			// if(start != null && stop != null)
			// {
			// 	if(start.get_time() != stop.get_time())
			// 	{
			// 		Gpx.Point f = this.track.points.first().data;
			// 		double elapsed_time = track.get_total_time();
			// 		double graph_width = alloc.width-LEFT_OFFSET-10;
			// 		double graph_height = alloc.height-20-BOTTOM_OFFSET;

			// 		ctx.set_source_rgba(0.3, 0.2, 0.3, 0.8);
			// 		ctx.rectangle((start.get_time()-f.get_time())/elapsed_time*graph_width, 0,
			// 				(stop.get_time()-start.get_time())/elapsed_time*graph_width, graph_height);
			// 		ctx.stroke_preserve();
			// 		ctx.fill();
			// 	}

			// }
// 			if(highlight > 0 )
// 			{
// 				Gpx.Point f = this.track.points.first().data;
// 				double elapsed_time = track.get_total_time();
// 				double graph_width = alloc.width-LEFT_OFFSET-10;
// 				double graph_height = alloc.height-20-BOTTOM_OFFSET;

// 				double hl = (highlight-f.get_time())/elapsed_time*graph_width;

// 				ctx.set_source_rgba(0.8, 0.2, 0.3, 0.8);
// 				ctx.move_to(hl, 0);
// 				ctx.line_to(hl,graph_height);

// 				ctx.stroke_preserve();
// 				ctx.fill();
// 				/* Draw the speed/elavation/distance
// 				 * in the upper top corner
// 				 */
// 				if(this.draw_current != null)
// 				{
// 					var layout = Pango.cairo_create_layout(ctx);
// 					int w,h;
// 					var text = "";
// 					var x_pos =0.0;

// 					text = _("Speed")+":\t"+       Gpx.Viewer.Misc.convert(this.draw_current.speed, 	Gpx.Viewer.Misc.SpeedFormat.SPEED);
// 					text += "\n"+_("Elevation")+":\t"+ Gpx.Viewer.Misc.convert(this.draw_current.elevation, Gpx.Viewer.Misc.SpeedFormat.ELEVATION);
// 					text += "\n"+_("Distance")+":\t"+Gpx.Viewer.Misc.convert(this.draw_current.distance,  Gpx.Viewer.Misc.SpeedFormat.DISTANCE);
//                     if(f.tpe.heartrate > 0) {
//                         text += "\n"+_("Heart-rate")+": "+"%d".printf(this.draw_current.tpe.heartrate)+_("(bpm)");
//                     }
//                     text += "\n"+_("Cadence")+":\t"+"%u rpm".printf(this.draw_current.cadence);

// 					fd.set_absolute_size(12*1024);
// 					layout.set_font_description(fd);
// 					layout.set_text(text,-1);
// 					layout.get_pixel_size(out w, out h);


// 					x_pos = (hl-(w+8)/2.0);
// 					if(x_pos < -LEFT_OFFSET) x_pos = 0.0;
// 					else if(hl+(w+8)/2.0 >= graph_width) x_pos = (double)graph_width - (double)(w+8.0);

// 					ctx.rectangle(x_pos, double.max(-h-2,-18), w+8, h+4);
// 					ctx.set_source_rgba(0.0, 0.0, 0.0, 1.0);
// 					ctx.stroke_preserve();
// 					ctx.set_source_rgba(0.7, 0.7, 0.7, 0.9);
// 					ctx.fill();

// 					ctx.move_to(x_pos+4,double.max(-h,-16));


// 					Pango.cairo_layout_path(ctx, layout);

// //					ctx.set_source_rgba(1.0, 1.0, 1.0, 1.0);
// //					ctx.stroke_preserve();
// 					ctx.set_source_rgba(0.0, 0.0, 0.0, 1.0);
// 					ctx.fill();
// 				}
// 			}
			return false;
		}
	}

	public class Graph
	{
		public Gpx.Track track = null;

		private int _smooth_factor = 1;
		private bool _show_points = true;
		private Graph2View view = new Graph2View();
		public int smooth_factor {
			get { return _smooth_factor;}
			set {
				_smooth_factor = value;
				/* Invalidate the previous plot, so it is redrawn */
				// this.surf = null;
				/* Force a redraw */
				// this.queue_draw();
			}
		}

		public bool show_points {
			get { return _show_points;}
			set {
				_show_points = value;
				/* Invalidate the previous plot, so it is redrawn */
				// this.surf = null;
				/* Force a redraw */
				// this.queue_draw();
			}
		}

		public void set_track(Gpx.Track? track)
		{
			// this.highlight = 0;
			this.track = track;
			print("SEtting trackt!:)");
			var data_elevation = new Gee.ArrayList<2DPoint?>();
			var data_heart = new Gee.ArrayList<2DPoint?>();
			var data_speed = new Gee.ArrayList<2DPoint?>();
			foreach (Point p in track.points) {
				data_elevation.add({p.distance, p.elevation});
				data_heart.add({p.distance, p.tpe.heartrate});
				data_speed.add({p.distance, p.speed});
			}
			this.view.add_data(data_elevation, 1, {0.2, 0.0, 0.7, 1}, {0.2, 0.0, 0.7, 0.4});
			this.view.add_data(data_heart, -2, {1, 0.0, 0.0, 1}, null);
			this.view.add_data(data_speed, -1, {0.1, 0.7, 0.2, 1}, null);
			this.view.plot();
			/* Invalidate the previous plot, so it is redrawn */
			// this.surf = null;
			// /* Force a redraw */
			// this.queue_draw();
			// this.start = null;
			// this.stop = null;
			/* */
			// if(this.track != null && this.track.points != null)
			// 	selection_changed(this.track, this.track.points.first().data, this.track.points.last().data);
			// else
			// 	selection_changed(this.track, null, null);
		}

		public void add_graph_to_container(Gtk.Container container) {
			print("ADDING THE pgrahs");

			container.add(this.view);
			this.view.show();
			container.show_all();
		}

		/** 
		 * @param p A Gpx.Point we want to highlight.
		 * pass null to unhighlight.
		 */
		public void highlight_point(Gpx.Point? p) 
		{
			time_t pt = (p == null)?0:p.get_time();
			this.set_highlight(pt);
		}
		public void set_highlight (time_t highlight) {
			// this.highlight = highlight;
			/* Force a redraw */
			// this.queue_draw();
		}

		public void hide_info()
		{
			// draw_current = null;
			// this.queue_draw();
		}
		public void show_info(Gpx.Point? cur_point)
		{
			// this.draw_current = cur_point;
			// this.queue_draw();
		}

	}
}