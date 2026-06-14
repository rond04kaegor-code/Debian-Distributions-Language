#ifndef DDL_BROWSER_RUNTIME_H
#define DDL_BROWSER_RUNTIME_H
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
namespace ddl {
class Browser {
    GtkWidget *window, *webview, *url_entry, *status_label;
    std::string homepage;
    static void on_destroy(GtkWidget*,gpointer){gtk_main_quit();}
    static void on_go(GtkWidget*,gpointer d){
        Browser* b=static_cast<Browser*>(d);
        const char* url=gtk_entry_get_text(GTK_ENTRY(b->url_entry));
        std::string u=url;
        if(u.find("://")==std::string::npos)u="https://"+u;
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(b->webview),u.c_str());
    }
public:
    Browser(const std::string& home="https://ddlanguage.org"):homepage(home){
        static bool init=false;
        if(!init){gtk_init(NULL,NULL);init=true;}
    }
    void create(int w=1200,int h=800){
        window=gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_window_set_title(GTK_WINDOW(window),"DDL Browser");
        gtk_window_set_default_size(GTK_WINDOW(window),w,h);
        g_signal_connect(window,"destroy",G_CALLBACK(on_destroy),NULL);
        GtkWidget* main_box=gtk_box_new(GTK_ORIENTATION_VERTICAL,0);
        gtk_container_add(GTK_CONTAINER(window),main_box);
        GtkWidget* toolbar=gtk_box_new(GTK_ORIENTATION_HORIZONTAL,6);
        auto mkbtn=[](const char* l,void(*cb)(GtkWidget*,gpointer),gpointer d){
            GtkWidget* b=gtk_button_new_with_label(l);
            g_signal_connect(b,"clicked",G_CALLBACK(cb),d);
            return b;
        };
        gtk_box_pack_start(GTK_BOX(toolbar),mkbtn("<",+[](GtkWidget*,gpointer d){webkit_web_view_go_back(WEBKIT_WEB_VIEW(static_cast<Browser*>(d)->webview));},this),FALSE,FALSE,0);
        gtk_box_pack_start(GTK_BOX(toolbar),mkbtn(">",+[](GtkWidget*,gpointer d){webkit_web_view_go_forward(WEBKIT_WEB_VIEW(static_cast<Browser*>(d)->webview));},this),FALSE,FALSE,0);
        gtk_box_pack_start(GTK_BOX(toolbar),mkbtn("R",+[](GtkWidget*,gpointer d){webkit_web_view_reload(WEBKIT_WEB_VIEW(static_cast<Browser*>(d)->webview));},this),FALSE,FALSE,0);
        gtk_box_pack_start(GTK_BOX(toolbar),mkbtn("H",+[](GtkWidget*,gpointer d){Browser* b=static_cast<Browser*>(d);webkit_web_view_load_uri(WEBKIT_WEB_VIEW(b->webview),b->homepage.c_str());},this),FALSE,FALSE,0);
        url_entry=gtk_entry_new();
        gtk_entry_set_text(GTK_ENTRY(url_entry),homepage.c_str());
        g_signal_connect(url_entry,"activate",G_CALLBACK(on_go),this);
        gtk_box_pack_start(GTK_BOX(toolbar),url_entry,TRUE,TRUE,6);
        gtk_box_pack_start(GTK_BOX(toolbar),mkbtn("Go",on_go,this),FALSE,FALSE,0);
        gtk_box_pack_start(GTK_BOX(main_box),toolbar,FALSE,FALSE,0);
        webview=webkit_web_view_new();
        WebKitSettings* s=webkit_web_view_get_settings(WEBKIT_WEB_VIEW(webview));
        webkit_settings_set_enable_javascript(s,TRUE);
        GtkWidget* scrolled=gtk_scrolled_window_new(NULL,NULL);
        gtk_container_add(GTK_CONTAINER(scrolled),webview);
        gtk_box_pack_start(GTK_BOX(main_box),scrolled,TRUE,TRUE,0);
        GtkWidget* status_bar=gtk_box_new(GTK_ORIENTATION_HORIZONTAL,10);
        status_label=gtk_label_new("Ready");
        gtk_box_pack_start(GTK_BOX(status_bar),status_label,TRUE,TRUE,0);
        gtk_box_pack_start(GTK_BOX(main_box),status_bar,FALSE,FALSE,0);
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview),homepage.c_str());
    }
    void show(){create();gtk_widget_show_all(window);}
    void run(){gtk_main();}
};
inline Browser* create_browser(const std::string& t,const std::string& u,int w,int h){
    Browser* b=new Browser(u);
    b->create(w,h);
    return b;
}
}
#endif
