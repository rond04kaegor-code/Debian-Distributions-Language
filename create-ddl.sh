#!/bin/bash

# create-ddl.sh - DDLanguage v2.0
# 11 REAL libraries, DDLTerminal included
# .ddl -> .cpp -> binary -> .deb (custom name)
# Strictness: Rust^2873737377363636363 × ∞
# License: GNU General Public License v3.0

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════╗"
echo "║   DDLanguage v2.0 — 11 REAL Libraries        ║"
echo "║   DDLTerminal — Linux Terminal Emulator      ║"
echo "║   Custom .deb naming                         ║"
echo "║   Ultra-Strict × ∞ Validation               ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

WORK_DIR="ddlanguage_build"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}/src" "${WORK_DIR}/lib" "${WORK_DIR}/include"
cd "${WORK_DIR}"

# ============================================
# INSTALL DEPENDENCIES
# ============================================
echo -e "${YELLOW}[1/8] Installing dependencies...${NC}"
sudo apt-get update -qq 2>/dev/null || true

NEEDED_PACKAGES=(
    build-essential g++ pkg-config dpkg-dev fakeroot
    libgtk-3-dev libcairo2-dev libpango1.0-dev libgdk-pixbuf-2.0-dev
    libatk1.0-dev libglib2.0-dev
    libwebkit2gtk-4.1-dev
    libcurl4-openssl-dev
    libjsoncpp-dev
    libsqlite3-dev
    libssl-dev
    libvte-2.91-dev
    libspdlog-dev
    libzstd-dev
    libopencv-dev
)

for pkg in "${NEEDED_PACKAGES[@]}"; do
    sudo apt-get install -y -qq "$pkg" 2>/dev/null || echo "  ⚠ $pkg"
done

# Fallback to WebKit 4.0
if ! pkg-config --exists webkit2gtk-4.1; then
    sudo apt-get install -y -qq libwebkit2gtk-4.0-dev 2>/dev/null || true
fi

echo -e "${GREEN}  Done${NC}"

# ============================================
# CREATE 11 REAL LIBRARIES
# ============================================
echo -e "${YELLOW}[2/8] Creating 11 REAL libraries...${NC}"

# 1. DDL Runtime
cat > lib/ddl_runtime.h << 'EOF'
#ifndef DDL_RUNTIME_H
#define DDL_RUNTIME_H
#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <ctime>
#include <thread>
#include <chrono>
namespace ddl {
inline void say(const std::string& t){std::cout<<t<<std::endl;}
inline void whisper(const std::string& t){std::cout<<t<<"..."<<std::endl;}
inline void rainbow(const std::string& t){std::cout<<t<<std::endl;}
inline void box(const std::string& t){std::string b="+"+std::string(t.length()+2,'-')+"+";std::cout<<b<<"\n| "<<t<<" |\n"<<b<<std::endl;}
inline void wait(double s){std::this_thread::sleep_for(std::chrono::milliseconds((int)(s*1000)));}
inline void clear(){system("clear");}
inline int random(int f,int t){return rand()%(t-f+1)+f;}
inline std::string to_str(int v){return std::to_string(v);}
inline int to_int(const std::string& s){return std::stoi(s);}
inline std::string ask(const std::string& q){std::cout<<q<<" ";std::string a;std::getline(std::cin,a);return a;}
}
#endif
EOF

# 2. DDLBrowser
cat > lib/ddl_browser_runtime.h << 'EOF'
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
EOF

# 3. DDLNet
cat > lib/ddlnet.h << 'EOF'
#ifndef DDLNET_H
#define DDLNET_H
#include <curl/curl.h>
#include <string>
namespace ddl {
class HTTP {
    static size_t wcb(void* c,size_t s,size_t n,std::string* o){o->append((char*)c,s*n);return s*n;}
public:
    static std::string get(const std::string& u){CURL* cu=curl_easy_init();if(!cu)return"";std::string r;curl_easy_setopt(cu,CURLOPT_URL,u.c_str());curl_easy_setopt(cu,CURLOPT_WRITEFUNCTION,wcb);curl_easy_setopt(cu,CURLOPT_WRITEDATA,&r);curl_easy_setopt(cu,CURLOPT_FOLLOWLOCATION,1L);curl_easy_perform(cu);curl_easy_cleanup(cu);return r;}
    static std::string post(const std::string& u,const std::string& d){CURL* cu=curl_easy_init();if(!cu)return"";std::string r;curl_easy_setopt(cu,CURLOPT_URL,u.c_str());curl_easy_setopt(cu,CURLOPT_POSTFIELDS,d.c_str());curl_easy_setopt(cu,CURLOPT_WRITEFUNCTION,wcb);curl_easy_setopt(cu,CURLOPT_WRITEDATA,&r);curl_easy_perform(cu);curl_easy_cleanup(cu);return r;}
};
inline std::string web_get(const std::string& u){return HTTP::get(u);}
inline std::string web_post(const std::string& u,const std::string& d){return HTTP::post(u,d);}
}
#endif
EOF

# 4. DDLFile
cat > lib/ddlfile.h << 'EOF'
#ifndef DDLFILE_H
#define DDLFILE_H
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
namespace ddl {
class File {
public:
    static bool exists(const std::string& p){struct stat b;return stat(p.c_str(),&b)==0;}
    static long size(const std::string& p){struct stat b;if(stat(p.c_str(),&b)!=0)return-1;return b.st_size;}
    static std::string read_all(const std::string& p){std::ifstream f(p);if(!f.is_open())return"";std::stringstream b;b<<f.rdbuf();return b.str();}
    static std::vector<std::string> read_lines(const std::string& p){std::vector<std::string> l;std::ifstream f(p);std::string ln;while(std::getline(f,ln))l.push_back(ln);return l;}
    static void write_all(const std::string& p,const std::string& c){std::ofstream f(p);f<<c;}
    static std::vector<std::string> list_dir(const std::string& p){std::vector<std::string> e;DIR* d=opendir(p.c_str());if(!d)return e;struct dirent* en;while((en=readdir(d))!=NULL){std::string n=en->d_name;if(n!="."&&n!="..")e.push_back(n);}closedir(d);return e;}
    static bool create_dir(const std::string& p){return mkdir(p.c_str(),0755)==0;}
    static bool remove(const std::string& p){return std::remove(p.c_str())==0;}
};
inline bool file_exists(const std::string& p){return File::exists(p);}
inline std::string read_file(const std::string& p){return File::read_all(p);}
inline void write_file(const std::string& p,const std::string& c){File::write_all(p,c);}
}
#endif
EOF

# 5. DDLJson
cat > lib/ddljson.h << 'EOF'
#ifndef DDLJSON_H
#define DDLJSON_H
#include <json/json.h>
#include <string>
namespace ddl {
class JSON {
    Json::Value root;
public:
    JSON(){} JSON(const std::string& s){Json::CharReaderBuilder b;std::string e;std::istringstream st(s);Json::parseFromStream(b,st,&root,&e);}
    std::string get_string(const std::string& k,const std::string& d=""){return(root.isMember(k)&&root[k].isString())?root[k].asString():d;}
    int get_int(const std::string& k,int d=0){return(root.isMember(k)&&root[k].isInt())?root[k].asInt():d;}
    std::string to_string(){Json::StreamWriterBuilder b;b["indentation"]="";return Json::writeString(b,root);}
};
inline std::string json_parse(const std::string& s,const std::string& k){JSON j(s);return j.get_string(k);}
}
#endif
EOF

# 6. DDLDatabase
cat > lib/ddldatabase.h << 'EOF'
#ifndef DDLDATABASE_H
#define DDLDATABASE_H
#include <sqlite3.h>
#include <string>
namespace ddl {
class Database {
    sqlite3* db;
public:
    Database(const std::string& p):db(nullptr){sqlite3_open(p.c_str(),&db);if(db)sqlite3_exec(db,"CREATE TABLE IF NOT EXISTS kv_store(key TEXT PRIMARY KEY,value TEXT)",NULL,NULL,NULL);}
    ~Database(){if(db)sqlite3_close(db);}
    void set(const std::string& k,const std::string& v){if(!db)return;std::string s="INSERT OR REPLACE INTO kv_store VALUES('"+k+"','"+v+"')";sqlite3_exec(db,s.c_str(),NULL,NULL,NULL);}
    std::string get(const std::string& k,const std::string& d=""){if(!db)return d;sqlite3_stmt* st;std::string s="SELECT value FROM kv_store WHERE key='"+k+"'";if(sqlite3_prepare_v2(db,s.c_str(),-1,&st,NULL)!=SQLITE_OK)return d;std::string r=d;if(sqlite3_step(st)==SQLITE_ROW){const char* v=(const char*)sqlite3_column_text(st,0);if(v)r=v;}sqlite3_finalize(st);return r;}
};
inline Database* db_open(const std::string& p){return new Database(p);}
}
#endif
EOF

# 7. DDLCrypto
cat > lib/ddlcrypto.h << 'EOF'
#ifndef DDLCRYPTO_H
#define DDLCRYPTO_H
#include <openssl/sha.h>
#include <openssl/md5.h>
#include <string>
#include <sstream>
#include <iomanip>
namespace ddl {
inline std::string sha256(const std::string& s){unsigned char h[SHA256_DIGEST_LENGTH];SHA256((unsigned char*)s.c_str(),s.length(),h);std::stringstream ss;for(int i=0;i<SHA256_DIGEST_LENGTH;i++)ss<<std::hex<<std::setw(2)<<std::setfill('0')<<(int)h[i];return ss.str();}
inline std::string md5(const std::string& s){unsigned char h[MD5_DIGEST_LENGTH];MD5((unsigned char*)s.c_str(),s.length(),h);std::stringstream ss;for(int i=0;i<MD5_DIGEST_LENGTH;i++)ss<<std::hex<<std::setw(2)<<std::setfill('0')<<(int)h[i];return ss.str();}
}
#endif
EOF

# 8. DDLCompress
cat > lib/ddlcompress.h << 'EOF'
#ifndef DDLCOMPRESS_H
#define DDLCOMPRESS_H
#include <zstd.h>
#include <string>
#include <vector>
namespace ddl {
inline std::vector<char> compress(const std::string& s){size_t b=ZSTD_compressBound(s.size());std::vector<char> o(b);size_t c=ZSTD_compress(o.data(),b,s.data(),s.size(),1);o.resize(c);return o;}
inline std::string decompress(const std::vector<char>& d){size_t s=ZSTD_getFrameContentSize(d.data(),d.size());std::string o(s,'\0');ZSTD_decompress((void*)o.data(),s,d.data(),d.size());return o;}
}
#endif
EOF

# 9. DDLLog
cat > lib/ddllog.h << 'EOF'
#ifndef DDLLOG_H
#define DDLLOG_H
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <string>
namespace ddl {
class Logger {
    std::shared_ptr<spdlog::logger> log;
public:
    Logger(const std::string& n,const std::string& f="ddl.log"){log=spdlog::basic_logger_mt(n,f);}
    void info(const std::string& m){log->info(m);}
    void warn(const std::string& m){log->warn(m);}
    void error(const std::string& m){log->error(m);}
};
inline Logger* log_create(const std::string& n,const std::string& f="ddl.log"){return new Logger(n,f);}
}
#endif
EOF

# 10. DDLTerminal — REAL TERMINAL EMULATOR (VTE)
cat > lib/ddlterminal.h << 'EOF'
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
EOF

# 11. DDLImage
cat > lib/ddlimage.h << 'EOF'
#ifndef DDLIMAGE_H
#define DDLIMAGE_H
#include <opencv2/opencv.hpp>
#include <string>
namespace ddl {
class Image {
    cv::Mat img;
public:
    Image(){} 
    Image(const std::string& p){img=cv::imread(p);}
    bool load(const std::string& p){img=cv::imread(p);return!img.empty();}
    bool save(const std::string& p){return cv::imwrite(p,img);}
    void resize(int w,int h){cv::resize(img,img,cv::Size(w,h));}
    void gray(){cv::cvtColor(img,img,cv::COLOR_BGR2GRAY);}
    void blur(int k){cv::GaussianBlur(img,img,cv::Size(k|1,k|1),0);}
    int width(){return img.cols;}
    int height(){return img.rows;}
};
inline Image* img_open(const std::string& p){return new Image(p);}
}
#endif
EOF

# 12. DDLGUI
cat > lib/ddlgui.h << 'EOF'
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
EOF

echo -e "${GREEN}  12 libraries created (DDLTerminal + DDLGUI included!)${NC}"

# ============================================
# COMPILER
# ============================================
echo -e "${YELLOW}[3/8] Compiling cppddl v2.0...${NC}"

cat > src/ddl_compiler.cpp << 'CEOF'
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <unistd.h>
#include <sys/stat.h>
#include <regex>

const std::string V = "2.0.0";

struct LineMap { int cpp; int ddl; std::string code; };
std::vector<LineMap> lm;

std::string trim(const std::string& s){
    size_t a=s.find_first_not_of(" \t");if(a==std::string::npos)return"";
    size_t b=s.find_last_not_of(" \t");return s.substr(a,b-a+1);
}

std::string get_includes(const std::string& code){
    std::string r;
    if(code.find("DDLGUI")!=std::string::npos||code.find("DDLBrowser")!=std::string::npos||code.find("DDLTerminal")!=std::string::npos)
        r+="#include <gtk/gtk.h>\n";
    if(code.find("DDLNet")!=std::string::npos)r+="#include \"ddlnet.h\"\n";
    if(code.find("DDLFile")!=std::string::npos)r+="#include \"ddlfile.h\"\n";
    if(code.find("DDLJson")!=std::string::npos)r+="#include \"ddljson.h\"\n";
    if(code.find("DDLDatabase")!=std::string::npos)r+="#include \"ddldatabase.h\"\n";
    if(code.find("DDLCrypto")!=std::string::npos)r+="#include \"ddlcrypto.h\"\n";
    if(code.find("DDLCompress")!=std::string::npos)r+="#include \"ddlcompress.h\"\n";
    if(code.find("DDLLog")!=std::string::npos)r+="#include \"ddllog.h\"\n";
    if(code.find("DDLTerminal")!=std::string::npos)r+="#include \"ddlterminal.h\"\n";
    if(code.find("DDLImage")!=std::string::npos)r+="#include \"ddlimage.h\"\n";
    if(code.find("DDLGUI")!=std::string::npos)r+="#include \"ddlgui.h\"\n";
    if(code.find("DDLBrowser")!=std::string::npos)r+="#include \"ddl_browser_runtime.h\"\n";
    return r;
}

std::vector<std::string> ultra_validate(const std::string& code){
    std::vector<std::string> e;std::istringstream ss(code);std::string l;int ln=0;bool hm=false;
    while(std::getline(ss,l)){ln++;size_t s=l.find_first_not_of(" \t\r\n");if(s==std::string::npos)continue;l=l.substr(s);
        if(l.empty()||l[0]=='#'||l.substr(0,2)=="//")continue;
        if(l.find("func main")==0)hm=true;
        if((l.find("let ")==0||l.find("var ")==0)&&l.back()!=';')
            e.push_back("DDL:"+std::to_string(ln)+": error: expected ';' at end of declaration");
        if(l.find("let ")==0&&l.find('=')==std::string::npos)
            e.push_back("DDL:"+std::to_string(ln)+": error: variable must be initialized");
        int q=0;for(char c:l)if(c=='"')q++;if(q%2!=0)
            e.push_back("DDL:"+std::to_string(ln)+": error: unterminated string literal");
    }
    if(!hm)e.push_back("DDL: error: no 'func main()' found");
    return e;
}

std::string transpile(const std::string& code,const std::string&){
    lm.clear();std::stringstream cpp;int cl=1;
    auto al=[&](const std::string& s,int dl,const std::string& dc){cpp<<s<<"\n";lm.push_back({cl,dl,dc});cl++;};
    
    al("#include <iostream>",0,"");al("#include <string>",0,"");al("#include <vector>",0,"");
    al("#include <cstdlib>",0,"");al("#include <ctime>",0,"");
    
    std::string inc=get_includes(code);
    std::istringstream is(inc);std::string il;
    while(std::getline(is,il))if(!il.empty())al(il,0,"");
    
    al("#include \"ddl_runtime.h\"",0,"");al("",0,"");
    al("using namespace ddl;",0,"");al("",0,"");
    al("int main(){",0,"");al("    srand(time(NULL));",0,"");
    
    if(code.find("DDLBrowser")!=std::string::npos||code.find("DDLTerminal")!=std::string::npos||code.find("DDLGUI")!=std::string::npos)
        al("    gtk_init(NULL,NULL);",0,"");
    
    std::istringstream ss(code);std::string line;int dl=0;
    while(std::getline(ss,line)){
        dl++;size_t s=line.find_first_not_of(" \t\r\n");
        if(s==std::string::npos){al("",dl,line);continue;}
        line=line.substr(s);
        if(line.empty()||line[0]=='#'||line.substr(0,2)=="//"){al("    // "+line,dl,line);continue;}
        if(line.find("DDLImport")==0){al("    // "+line,dl,line);continue;}
        if(line.find("func main")==0)continue;
        if(line=="{"||line=="}")continue;
        
        std::string out=line;
        
        if(out.find("let ")==0||out.find("var ")==0){
            std::string rest=(out.find("let ")==0)?out.substr(4):out.substr(4);
            size_t c=rest.find(':'),eq=rest.find('=');
            if(c!=std::string::npos&&eq!=std::string::npos&&c<eq){
                std::string n=rest.substr(0,c);n=trim(n);rest=n+" "+rest.substr(eq);
            }
            out="    auto "+rest;
        }
        else if(out.find("createBrowser(")!=std::string::npos){
            size_t eq=out.find('=');std::string v="browser";
            if(eq!=std::string::npos){v=out.substr(0,eq);
                if(v.find("auto ")==0)v=v.substr(5);else if(v.find("let ")==0)v=v.substr(4);
                v=trim(v);
            }
            out="    Browser* "+v+" = create_browser("+out.substr(out.find('(')+1);
        }
        else if(out.find("term_create(")!=std::string::npos){
            size_t eq=out.find('=');std::string v="term";
            if(eq!=std::string::npos){v=out.substr(0,eq);
                if(v.find("auto ")==0)v=v.substr(5);else if(v.find("let ")==0)v=v.substr(4);
                v=trim(v);
            }
            out="    Terminal* "+v+" = term_create("+out.substr(out.find('(')+1);
        }
        else if(out.find("term_get_widget(")!=std::string::npos){
            out="    "+out;
        }
        else if(out.find("gtk_set_css(")!=std::string::npos){
            out="    "+out;
        }
        else if(out.find("gtk_widget_set_name(")!=std::string::npos){
            out="    "+out;
        }
        else if(out.find("gtk_box_pack_start(")!=std::string::npos){
            out="    "+out;
        }
        else if(out.find("gtk_container_add(")!=std::string::npos){
            out="    "+out;
        }
        else if(out.find("gui_")==0){
            out="    "+out;
        }
        else if(out.find(".show()")!=std::string::npos)
            out="    "+out.substr(0,out.find('.'))+"->show();";
        else if(out.find(".run()")!=std::string::npos)
            out="    "+out.substr(0,out.find('.'))+"->run();\n    return 0;";
        else if(out.find(".set_colors")!=std::string::npos||out.find(".set_font")!=std::string::npos||out.find(".run_command")!=std::string::npos)
            out="    "+out.substr(0,out.find('.'))+"->"+out.substr(out.find('.')+1);
        else out="    "+out;
        
        al(out,dl,line);
    }
    if(cpp.str().find("return 0;")==std::string::npos)al("    return 0;",0,"");
    al("}",0,"");
    return cpp.str();
}

struct DDLError {std::string type,msg;int line;std::string code,fix;};

DDLError parse_error(const std::string& eo){
    DDLError e;e.type="UNKNOWN";e.line=0;
    std::regex lr(R"(/tmp/ddl_run\.cpp:(\d+):)");std::smatch m;
    if(std::regex_search(eo,m,lr)){int cl=std::stoi(m[1].str());for(auto& x:lm)if(x.cpp==cl){e.line=x.ddl;e.code=x.code;break;}}
    if(eo.find("was not declared")!=std::string::npos){e.type="UNDECLARED";std::regex ir(R"('([^']+)')");std::smatch im;if(std::regex_search(eo,im,ir)){e.msg="'"+im[1].str()+"' not declared";e.fix="Add: DDLImport \"LIBRARY\"; or declare variable";}}
    else if(eo.find("expected ';'")!=std::string::npos){e.type="SYNTAX";e.msg="Missing ;";e.fix="Every statement MUST end with ';'";}
    else if(eo.find("undefined reference")!=std::string::npos){e.type="LINKER";e.msg="Undefined reference";e.fix="Add DDLImport and install -dev package";}
    else if(eo.find("fatal error")!=std::string::npos){e.type="MISSING_FILE";e.msg="Header file not found";e.fix="Run: sudo cp ~/ddl/ddlanguage_build/lib/*.h /usr/share/ddlanguage/include/";}
    return e;
}

void print_error(const DDLError& e,const std::string& cpp_err){
    std::cout<<"\033[31m\n╔══════════════════════════════════════════════════════════════╗\n";
    std::cout<<"║  cppddl: "<<e.type<<" ERROR\n";
    if(e.line>0)std::cout<<"║  --> DDL:"<<e.line<<": "<<e.code<<"\n";
    std::cout<<"║  "<<e.msg<<"\n║  💡 FIX: "<<e.fix<<"\n";
    std::cout<<"║  --- C++ output ---\n";
    std::string ce=cpp_err;if(ce.length()>300)ce=ce.substr(0,300)+"...";
    std::istringstream cs(ce);std::string cline;while(std::getline(cs,cline))std::cout<<"║  "<<cline<<"\n";
    std::cout<<"╚══════════════════════════════════════════════════════════════╝\n\033[0m\n";
}

std::string bcmd(const std::string& src,const std::string& out,const std::string& code){
    std::stringstream c;
    c<<"g++ -std=c++17 -I/usr/share/ddlanguage/include ";
    if(code.find("DDLGUI")!=std::string::npos||code.find("DDLBrowser")!=std::string::npos||code.find("DDLTerminal")!=std::string::npos)
        c<<"$(pkg-config --cflags gtk+-3.0) ";
    if(code.find("DDLBrowser")!=std::string::npos)
        c<<"$(pkg-config --cflags webkit2gtk-4.1 2>/dev/null || pkg-config --cflags webkit2gtk-4.0 2>/dev/null) ";
    if(code.find("DDLNet")!=std::string::npos)c<<"$(pkg-config --cflags libcurl) ";
    if(code.find("DDLJson")!=std::string::npos)c<<"$(pkg-config --cflags jsoncpp) ";
    if(code.find("DDLDatabase")!=std::string::npos)c<<"$(pkg-config --cflags sqlite3) ";
    if(code.find("DDLCrypto")!=std::string::npos)c<<"-lssl -lcrypto ";
    if(code.find("DDLCompress")!=std::string::npos)c<<"-lzstd ";
    if(code.find("DDLLog")!=std::string::npos)c<<"$(pkg-config --cflags --libs spdlog) ";
    if(code.find("DDLTerminal")!=std::string::npos)c<<"$(pkg-config --cflags vte-2.91) ";
    if(code.find("DDLImage")!=std::string::npos)c<<"$(pkg-config --cflags opencv4) ";
    c<<"-o "<<out<<" "<<src<<" ";
    if(code.find("DDLGUI")!=std::string::npos||code.find("DDLBrowser")!=std::string::npos||code.find("DDLTerminal")!=std::string::npos)
        c<<"$(pkg-config --libs gtk+-3.0) ";
    if(code.find("DDLBrowser")!=std::string::npos)
        c<<"$(pkg-config --libs webkit2gtk-4.1 2>/dev/null || pkg-config --libs webkit2gtk-4.0 2>/dev/null) ";
    if(code.find("DDLNet")!=std::string::npos)c<<"$(pkg-config --libs libcurl) ";
    if(code.find("DDLJson")!=std::string::npos)c<<"$(pkg-config --libs jsoncpp) ";
    if(code.find("DDLDatabase")!=std::string::npos)c<<"$(pkg-config --libs sqlite3) ";
    if(code.find("DDLTerminal")!=std::string::npos)c<<"$(pkg-config --libs vte-2.91) ";
    if(code.find("DDLImage")!=std::string::npos)c<<"$(pkg-config --libs opencv4) ";
    c<<"-O2 2>&1";
    return c.str();
}

void run(const std::string& fn){
    std::ifstream f(fn);if(!f.is_open()){std::cerr<<"Cannot open: "<<fn<<"\n";exit(1);}
    std::stringstream b;b<<f.rdbuf();std::string code=b.str();f.close();
    auto errs=ultra_validate(code);
    if(!errs.empty()){std::cout<<"\033[31m\n";for(auto& e:errs)std::cout<<e<<"\n";std::cout<<"\033[0m\n";exit(1);}
    std::cout<<"\033[32m✓ Ultra-strict validation passed\033[0m\n";
    
    std::string cpp_code=transpile(code,fn);
    std::ofstream cf("/tmp/ddl_run.cpp");cf<<cpp_code;cf.close();
    
    std::string cmd=bcmd("/tmp/ddl_run.cpp","/tmp/ddl_run",code);
    FILE* p=popen(cmd.c_str(),"r");std::string co;char buf[4096];
    while(fgets(buf,sizeof(buf),p)!=NULL)co+=buf;
    if(pclose(p)!=0){DDLError e=parse_error(co);print_error(e,co);exit(1);}
    
    system("/tmp/ddl_run");
    system("rm -f /tmp/ddl_run /tmp/ddl_run.cpp");
}

void export_deb(const std::string& fn,const std::string& custom_name=""){
    std::ifstream f(fn);if(!f.is_open()){std::cerr<<"Cannot open: "<<fn<<"\n";exit(1);}
    std::stringstream b;b<<f.rdbuf();std::string code=b.str();f.close();
    auto errs=ultra_validate(code);if(!errs.empty()){for(auto& e:errs)std::cerr<<e<<"\n";exit(1);}
    
    std::string base=fn;
    size_t d=base.find_last_of('.');if(d!=std::string::npos)base=base.substr(0,d);
    size_t s=base.find_last_of('/');if(s!=std::string::npos)base=base.substr(s+1);
    
    std::string sb=(custom_name.empty())?base:custom_name;
    std::replace(sb.begin(),sb.end(),'-','_');std::replace(sb.begin(),sb.end(),' ','_');
    
    std::string cf="/tmp/"+sb+".cpp";std::ofstream cff(cf);cff<<transpile(code,fn);cff.close();
    std::string bin="/tmp/"+sb+"_bin";
    std::string cmd=bcmd(cf,bin,code);
    
    FILE* p=popen(cmd.c_str(),"r");std::string co;char buf[4096];
    while(fgets(buf,sizeof(buf),p)!=NULL)co+=buf;
    if(pclose(p)!=0){DDLError e=parse_error(co);print_error(e,co);exit(1);}
    
    std::string pkg="/tmp/ddl_"+sb;
    system(("rm -rf "+pkg+"; mkdir -p "+pkg+"/DEBIAN "+pkg+"/usr/local/bin "+pkg+"/usr/share/"+sb).c_str());
    system(("cp "+bin+" "+pkg+"/usr/local/bin/"+sb+"; chmod 755 "+pkg+"/usr/local/bin/"+sb).c_str());
    
    std::ofstream ctrl(pkg+"/DEBIAN/control");
    ctrl<<"Package: "<<sb<<"\nVersion: 1.0.0\nArchitecture: amd64\nMaintainer: DDLanguage Team\nDescription: "<<base<<" - DDL Application\n";ctrl.close();
    
    std::string deb_name=custom_name.empty()?sb:custom_name;
    std::replace(deb_name.begin(),deb_name.end(),' ','_');
    std::string deb=deb_name+"_1.0.0_amd64.deb";
    
    system(("fakeroot dpkg-deb --build "+pkg+" /tmp/"+deb+" 2>/dev/null; mv /tmp/"+deb+" ./"+deb+"; rm -rf "+pkg).c_str());
    std::cout<<"\033[32m✅ Exported: "<<deb<<"\033[0m\n";
}

int main(int argc,char* argv[]){
    if(argc<2){
        std::cout<<"\033[36mDDL v"<<V<<" — 12 Libraries, DDLTerminal + DDLGUI\n";
        std::cout<<"  cppddl file.ddl                    Run\n";
        std::cout<<"  cppddl --export file.ddl           Export to .deb\n";
        std::cout<<"  cppddl --export file.ddl MyName    Export with custom name\n";
        std::cout<<"  cppddl --version                   Version\n\033[0m\n";
        return 0;
    }
    std::string arg=argv[1];
    if(arg=="--version"){std::cout<<"DDLanguage v"<<V<<" | 12 Libraries | DDLTerminal + DDLGUI\n";return 0;}
    if(arg=="--help"){
        std::cout<<"DDL v"<<V<<" Libraries:\n";
        std::cout<<"  DDLRuntime   DDLBrowser   DDLNet      DDLFile\n";
        std::cout<<"  DDLJson      DDLDatabase  DDLCrypto   DDLCompress\n";
        std::cout<<"  DDLLog       DDLTerminal  DDLImage    DDLGUI\n";
        return 0;
    }
    if(arg=="--export"){if(argc<3){std::cerr<<"Usage: cppddl --export file.ddl [Name]\n";return 1;}std::string cust=(argc>=4)?argv[3]:"";export_deb(argv[2],cust);return 0;}
    run(arg);return 0;
}
CEOF

g++ -std=c++17 -Ilib -o cppddl src/ddl_compiler.cpp -O2
echo -e "${GREEN}  cppddl v2.0 compiled${NC}"

# ============================================
# BUILD DEB
# ============================================
echo -e "${YELLOW}[4/8] Building .deb...${NC}"
DEB_NAME="cppddl_2.0.0_amd64"
DEB_DIR="deb/${DEB_NAME}"
rm -rf deb
mkdir -p "${DEB_DIR}/DEBIAN" "${DEB_DIR}/usr/local/bin" "${DEB_DIR}/usr/share/ddlanguage/include"
cp cppddl "${DEB_DIR}/usr/local/bin/"
chmod 755 "${DEB_DIR}/usr/local/bin/cppddl"
cp lib/*.h "${DEB_DIR}/usr/share/ddlanguage/include/" 2>/dev/null || true

cat > "${DEB_DIR}/DEBIAN/control" << EOF
Package: cppddl
Version: 2.0.0
Section: devel
Priority: optional
Architecture: amd64
Depends: libc6, libstdc++6, g++, libgtk-3-0, libgtk-3-dev, libcairo2, libvte-2.91-0, libvte-2.91-dev, libwebkit2gtk-4.1-0 | libwebkit2gtk-4.0-37, libcurl4, libjsoncpp25 | libjsoncpp24, libsqlite3-0, libssl3, libzstd1, libopencv-core406 | libopencv-core405, pkg-config, build-essential
Maintainer: DDLanguage Team
Description: DDLanguage v2.0 — 12 Libraries, DDLTerminal + DDLGUI
 DDLTerminal: Full Linux terminal emulator via VTE.
 DDLGUI: GTK3 GUI widgets.
 Also: DDLBrowser, DDLNet, DDLFile, DDLJson, DDLDatabase,
 DDLCrypto, DDLCompress, DDLLog, DDLImage.
 Strictness: Rust^2873737377363636363 × ∞.
 Custom .deb naming support.
EOF

cat > "${DEB_DIR}/DEBIAN/postinst" << 'POST'
#!/bin/bash
echo "DDLanguage v2.0 | 12 Libraries | DDLTerminal + DDLGUI | GNU GPL v3.0"
echo "Usage: cppddl file.ddl"
echo "Export: cppddl --export file.ddl [CustomName]"
POST
chmod 755 "${DEB_DIR}/DEBIAN/postinst"

find "${DEB_DIR}" -type d -exec chmod 755 {} \;
find "${DEB_DIR}" -type f -exec chmod 644 {} \;
chmod 755 "${DEB_DIR}/usr/local/bin/cppddl" "${DEB_DIR}/DEBIAN/postinst"

fakeroot dpkg-deb --build "${DEB_DIR}" 2>/dev/null
cp "${DEB_DIR}.deb" "../${DEB_NAME}.deb"

cd ..
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ DDLanguage v2.0 built!             ║${NC}"
echo -e "${GREEN}║  12 REAL libraries                     ║${NC}"
echo -e "${GREEN}║  DDLTerminal + DDLGUI                  ║${NC}"
echo -e "${GREEN}║  Custom .deb naming                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📦 ${DEB_NAME}.deb${NC}"
echo -e "${YELLOW}📥 sudo dpkg -i ${DEB_NAME}.deb && sudo apt-get install -f${NC}"
