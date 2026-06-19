#ifndef DDL_BROWSER_RUNTIME_H
#define DDL_BROWSER_RUNTIME_H
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
namespace ddl {
class Browser {
    GtkWidget *window,*webview,*url_entry,*status_label;
    std::string homepage;
    static void on_destroy(GtkWidget*,gpointer){gtk_main_quit();}
    static void on_go(GtkWidget*,gpointer d){
        Browser* b=static_cast<Browser*>(d);
        const char* url=gtk_entry_get_text(GTK_ENTRY(b->url_entry));
        std::string u=url;if(u.find("://")==std::string::npos)u="https://"+u;
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(b->webview),u.c_str());
    }
public:
    Browser(const std::string& h="https://ddlanguage.org"):homepage(h){static bool i=false;if(!i){gtk_init(NULL,NULL);i=true;}}
    void create(int w=1200,int h=800){
        window=gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_window_set_title(GTK_WINDOW(window),"DDL Browser");
        gtk_window_set_default_size(GTK_WINDOW(window),w,h);
        g_signal_connect(window,"destroy",G_CALLBACK(on_destroy),NULL);
        GtkWidget* mb=gtk_box_new(GTK_ORIENTATION_VERTICAL,0);
        gtk_container_add(GTK_CONTAINER(window),mb);
        GtkWidget* tb=gtk_box_new(GTK_ORIENTATION_HORIZONTAL,6);
        auto mk=[&](const char* l,void(*c)(GtkWidget*,gpointer)){
            GtkWidget* b=gtk_button_new_with_label(l);
            g_signal_connect(b,"clicked",G_CALLBACK(c),this);
            gtk_box_pack_start(GTK_BOX(tb),b,FALSE,FALSE,0);
        };
        mk("<",+[](GtkWidget*,gpointer d){webkit_web_view_go_back(WEBKIT_WEB_VIEW(static_cast<Browser*>(d)->webview));});
        mk(">",+[](GtkWidget*,gpointer d){webkit_web_view_go_forward(WEBKIT_WEB_VIEW(static_cast<Browser*>(d)->webview));});
        mk("R",+[](GtkWidget*,gpointer d){webkit_web_view_reload(WEBKIT_WEB_VIEW(static_cast<Browser*>(d)->webview));});
        mk("H",+[](GtkWidget*,gpointer d){Browser* b=static_cast<Browser*>(d);webkit_web_view_load_uri(WEBKIT_WEB_VIEW(b->webview),b->homepage.c_str());});
        url_entry=gtk_entry_new();
        gtk_entry_set_text(GTK_ENTRY(url_entry),homepage.c_str());
        g_signal_connect(url_entry,"activate",G_CALLBACK(on_go),this);
        gtk_box_pack_start(GTK_BOX(tb),url_entry,TRUE,TRUE,6);
        GtkWidget* go=gtk_button_new_with_label("Go");
        g_signal_connect(go,"clicked",G_CALLBACK(on_go),this);
        gtk_box_pack_start(GTK_BOX(tb),go,FALSE,FALSE,0);
        gtk_box_pack_start(GTK_BOX(mb),tb,FALSE,FALSE,0);
        webview=webkit_web_view_new();
        WebKitSettings* s=webkit_web_view_get_settings(WEBKIT_WEB_VIEW(webview));
        webkit_settings_set_enable_javascript(s,TRUE);
        GtkWidget* sc=gtk_scrolled_window_new(NULL,NULL);
        gtk_container_add(GTK_CONTAINER(sc),webview);
        gtk_box_pack_start(GTK_BOX(mb),sc,TRUE,TRUE,0);
        GtkWidget* sb=gtk_box_new(GTK_ORIENTATION_HORIZONTAL,10);
        status_label=gtk_label_new("Ready");
        gtk_box_pack_start(GTK_BOX(sb),status_label,TRUE,TRUE,0);
        gtk_box_pack_start(GTK_BOX(mb),sb,FALSE,FALSE,0);
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview),homepage.c_str());
    }
    void show(){create();gtk_widget_show_all(window);}
    void run(){gtk_main();}
};
inline Browser* create_browser(const std::string& t,const std::string& u,int w,int h){
    Browser* b=new Browser(u);b->create(w,h);return b;
}
}
#endif
