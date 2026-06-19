#ifndef DDLGUI_H
#define DDLGUI_H
#include <gtk/gtk.h>
#include <string>
namespace ddl {
static void gtk_destroy(GtkWidget*,gpointer){gtk_main_quit();}
inline void gtk_set_css(const std::string& css){GtkCssProvider* p=gtk_css_provider_new();gtk_css_provider_load_from_data(p,css.c_str(),-1,NULL);gtk_style_context_add_provider_for_screen(gdk_screen_get_default(),GTK_STYLE_PROVIDER(p),GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);g_object_unref(p);}
inline GtkWidget* gui_window(const std::string& t,int w,int h){GtkWidget* win=gtk_window_new(GTK_WINDOW_TOPLEVEL);gtk_window_set_title(GTK_WINDOW(win),t.c_str());gtk_window_set_default_size(GTK_WINDOW(win),w,h);g_signal_connect(win,"destroy",G_CALLBACK(gtk_destroy),NULL);return win;}
inline GtkWidget* gui_button(const std::string& l){return gtk_button_new_with_label(l.c_str());}
inline GtkWidget* gui_label(const std::string& t){return gtk_label_new(t.c_str());}
inline GtkWidget* gui_entry(){return gtk_entry_new();}
inline GtkWidget* gui_box(int v){return gtk_box_new(v?GTK_ORIENTATION_VERTICAL:GTK_ORIENTATION_HORIZONTAL,0);}
inline void gui_show(GtkWidget* w){gtk_widget_show_all(w);}
inline void gui_run(){gtk_main();}
}
#endif
