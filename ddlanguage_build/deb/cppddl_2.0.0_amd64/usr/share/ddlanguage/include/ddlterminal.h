#ifndef DDLTERMINAL_H
#define DDLTERMINAL_H
#include <vte/vte.h>
#include <gtk/gtk.h>
#include <string>

namespace ddl {

class Terminal {
private:
    GtkWidget* window;
    GtkWidget* term;
    GtkWidget* scroll;
    
    static void on_destroy(GtkWidget*, gpointer) { gtk_main_quit(); }
    
public:
    Terminal() : window(nullptr), term(nullptr), scroll(nullptr) {
        static bool init = false;
        if (!init) { gtk_init(NULL, NULL); init = true; }
    }
    
    void create(const std::string& title, int w, int h) {
        window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_window_set_title(GTK_WINDOW(window), title.c_str());
        gtk_window_set_default_size(GTK_WINDOW(window), w, h);
        g_signal_connect(window, "destroy", G_CALLBACK(on_destroy), NULL);
        
        GtkWidget* vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
        gtk_container_add(GTK_CONTAINER(window), vbox);
        
        scroll = gtk_scrolled_window_new(NULL, NULL);
        gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll), GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
        
        term = vte_terminal_new();
        vte_terminal_set_scrollback_lines(VTE_TERMINAL(term), 10000);
        
        GdkRGBA fg = {1.0, 1.0, 1.0, 1.0};
        GdkRGBA bg = {0.12, 0.12, 0.12, 1.0};
        vte_terminal_set_colors(VTE_TERMINAL(term), &fg, &bg, NULL, 0);
        
        PangoFontDescription* font = pango_font_description_from_string("Monospace 11");
        vte_terminal_set_font(VTE_TERMINAL(term), font);
        pango_font_description_free(font);
        
        gtk_container_add(GTK_CONTAINER(scroll), term);
        gtk_box_pack_start(GTK_BOX(vbox), scroll, TRUE, TRUE, 0);
        
        const char* shell = g_getenv("SHELL");
        if (!shell || strlen(shell) == 0) shell = "/bin/bash";
        
        char* argv[2];
        argv[0] = (char*)shell;
        argv[1] = NULL;
        
        vte_terminal_spawn_async(VTE_TERMINAL(term), VTE_PTY_DEFAULT,
                                NULL, argv, NULL, G_SPAWN_DEFAULT,
                                NULL, NULL, NULL, -1, NULL, NULL, NULL);
        
        gtk_widget_grab_focus(term);
    }
    
    void run_command(const std::string& cmd) {
        if (term) {
            vte_terminal_feed_child(VTE_TERMINAL(term), cmd.c_str(), cmd.length());
            vte_terminal_feed_child(VTE_TERMINAL(term), "\n", 1);
        }
    }
    
    void set_font(const std::string& font_name, int size) {
        if (term) {
            std::string desc = font_name + " " + std::to_string(size);
            PangoFontDescription* font = pango_font_description_from_string(desc.c_str());
            vte_terminal_set_font(VTE_TERMINAL(term), font);
            pango_font_description_free(font);
        }
    }
    
    void set_colors(const std::string& fg_str, const std::string& bg_str) {
        if (term) {
            GdkRGBA fg, bg;
            gdk_rgba_parse(&fg, fg_str.c_str());
            gdk_rgba_parse(&bg, bg_str.c_str());
            vte_terminal_set_colors(VTE_TERMINAL(term), &fg, &bg, NULL, 0);
        }
    }
    
    GtkWidget* get_widget() { return scroll ? scroll : term; }
    
    void show() { gtk_widget_show_all(window); }
    void run() { gtk_main(); }
};

inline Terminal* term_create(const std::string& title, int w, int h) {
    Terminal* t = new Terminal();
    t->create(title, w, h);
    return t;
}

inline GtkWidget* term_get_widget(Terminal* t) {
    return t ? t->get_widget() : NULL;
}

}
#endif
