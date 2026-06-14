#!/bin/bash

# create-ddl.sh - DDLanguage v1.0
# .ddl -> .cpp -> binary, GTK3 + WebKit
# License: GNU General Public License v3.0

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   DDLanguage v1.0 - GTK3 + WebKit            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"

WORK_DIR="ddlanguage_build"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}/src" "${WORK_DIR}/lib"
cd "${WORK_DIR}"

echo -e "${YELLOW}[1/5] Installing dependencies...${NC}"
sudo apt-get update -qq 2>/dev/null || true
sudo apt-get remove -y -qq libgtk-4-dev libwebkitgtk-6.0-dev libwebkitgtk-6.0-4 2>/dev/null || true
sudo apt-get install -y -qq build-essential g++ pkg-config dpkg-dev fakeroot libgtk-3-dev libcairo2-dev libpango1.0-dev libgdk-pixbuf-2.0-dev libatk1.0-dev libglib2.0-dev 2>/dev/null || true
sudo apt-get install -y -qq libwebkit2gtk-4.1-dev 2>/dev/null || sudo apt-get install -y -qq libwebkit2gtk-4.0-dev 2>/dev/null || true
echo -e "${GREEN}  Done${NC}"

echo -e "${YELLOW}[2/5] Creating runtime...${NC}"

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
inline void say(const std::string& t) { std::cout << t << std::endl; }
inline void whisper(const std::string& t) { std::cout << t << "..." << std::endl; }
inline void rainbow(const std::string& t) { std::cout << t << std::endl; }
inline void box(const std::string& t) { std::string b="+"+std::string(t.length()+2,'-')+"+"; std::cout<<b<<"\n| "<<t<<" |\n"<<b<<std::endl; }
inline void wait(double s) { std::this_thread::sleep_for(std::chrono::milliseconds((int)(s*1000))); }
inline void clear() { system("clear"); }
inline void write_file(const std::string& n, const std::string& c) { std::ofstream f(n); f<<c; }
}
#endif
EOF

cat > lib/ddl_browser_runtime.h << 'EOF'
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
EOF

echo -e "${YELLOW}[3/5] Compiling cppddl...${NC}"

cat > src/ddl_compiler.cpp << 'CEOF'
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <unistd.h>
#include <sys/stat.h>

const std::string V="1.0.0";

std::string trim(const std::string& s){
    size_t a=s.find_first_not_of(" \t");
    if(a==std::string::npos)return"";
    size_t b=s.find_last_not_of(" \t");
    return s.substr(a,b-a+1);
}

std::string transpile(const std::string& code,const std::string&){
    std::stringstream cpp;
    bool has_browser=(code.find("DDLBrowser")!=std::string::npos);
    bool has_gfx=(code.find("DDLGraphic")!=std::string::npos);
    
    cpp<<"#include <iostream>\n#include <string>\n#include <cstdlib>\n#include <ctime>\n";
    if(has_gfx||has_browser)cpp<<"#include <gtk/gtk.h>\n";
    cpp<<"#include \"ddl_runtime.h\"\n";
    if(has_browser)cpp<<"#include \"ddl_browser_runtime.h\"\n";
    cpp<<"\nusing namespace ddl;\n\nint main(){\n    srand(time(NULL));\n";
    if(has_gfx||has_browser)cpp<<"    gtk_init(NULL,NULL);\n";
    
    std::istringstream ss(code);
    std::string line;
    while(std::getline(ss,line)){
        size_t s=line.find_first_not_of(" \t\r\n");
        if(s==std::string::npos){cpp<<"\n";continue;}
        line=line.substr(s);
        if(line.empty()||line[0]=='#'||line.substr(0,2)=="//")continue;
        if(line.find("DDLImport")==0)continue;
        if(line.find("func main")==0)continue;
        if(line=="{"||line=="}")continue;
        
        std::string out=line;
        
        // let x = ... -> auto x = ...
        if(out.find("let ")==0){
            std::string rest=out.substr(4);
            size_t col=rest.find(':');
            size_t eq=rest.find('=');
            if(col!=std::string::npos&&eq!=std::string::npos&&col<eq){
                std::string name=rest.substr(0,col);
                name=trim(name);
                rest=name+" "+rest.substr(eq);
            }
            out="    auto "+rest;
        }
        // var x = ... -> auto x = ...
        else if(out.find("var ")==0){
            out="    auto "+out.substr(4);
        }
        // createBrowser( -> Browser* var = create_browser(
        else if(out.find("createBrowser(")!=std::string::npos){
            size_t eq=out.find('=');
            std::string var="browser";
            if(eq!=std::string::npos){
                var=out.substr(0,eq);
                if(var.find("auto ")==0)var=var.substr(5);
                else if(var.find("let ")==0)var=var.substr(4);
                else if(var.find("var ")==0)var=var.substr(4);
                var=trim(var);
            }
            out="    Browser* "+var+" = create_browser("+out.substr(out.find('(')+1);
        }
        // .show() -> ->show();
        else if(out.find(".show()")!=std::string::npos){
            out="    "+out.substr(0,out.find('.'))+"->show();";
        }
        // .run() -> ->run();
        else if(out.find(".run()")!=std::string::npos){
            out="    "+out.substr(0,out.find('.'))+"->run();\n    return 0;";
        }
        else {
            out="    "+out;
        }
        cpp<<out<<"\n";
    }
    if(cpp.str().find("return 0;")==std::string::npos)cpp<<"    return 0;\n";
    cpp<<"}\n";
    return cpp.str();
}

std::string bcmd(const std::string& src,const std::string& out,bool has_gfx,bool has_browser){
    std::stringstream cmd;
    cmd<<"g++ -std=c++17 -I/usr/share/ddlanguage/include ";
    if(has_gfx||has_browser)cmd<<"$(pkg-config --cflags gtk+-3.0) ";
    if(has_browser){
        if(system("pkg-config --exists webkit2gtk-4.1 2>/dev/null")==0)
            cmd<<"$(pkg-config --cflags webkit2gtk-4.1) ";
        else
            cmd<<"$(pkg-config --cflags webkit2gtk-4.0 2>/dev/null) ";
    }
    cmd<<"-o "<<out<<" "<<src<<" ";
    if(has_gfx||has_browser)cmd<<"$(pkg-config --libs gtk+-3.0) ";
    if(has_browser){
        if(system("pkg-config --exists webkit2gtk-4.1 2>/dev/null")==0)
            cmd<<"$(pkg-config --libs webkit2gtk-4.1) ";
        else
            cmd<<"$(pkg-config --libs webkit2gtk-4.0 2>/dev/null) ";
    }
    cmd<<"-O2 2>&1";
    return cmd.str();
}

void run(const std::string& fn){
    std::ifstream f(fn);
    if(!f.is_open()){std::cerr<<"Cannot open: "<<fn<<"\n";exit(1);}
    std::stringstream b;b<<f.rdbuf();std::string code=b.str();f.close();
    
    std::string cpp_code=transpile(code,fn);
    std::ofstream cf("/tmp/ddl_run.cpp");cf<<cpp_code;cf.close();
    
    bool has_browser=(code.find("DDLBrowser")!=std::string::npos);
    bool has_gfx=(code.find("DDLGraphic")!=std::string::npos);
    
    if(system(bcmd("/tmp/ddl_run.cpp","/tmp/ddl_run",has_gfx,has_browser).c_str())==0){
        system("/tmp/ddl_run 2>/dev/null");
        system("rm -f /tmp/ddl_run /tmp/ddl_run.cpp");
    }
}

void export_deb(const std::string& fn){
    std::ifstream f(fn);
    if(!f.is_open()){std::cerr<<"Cannot open: "<<fn<<"\n";exit(1);}
    std::stringstream b;b<<f.rdbuf();std::string code=b.str();f.close();
    
    std::string base=fn;
    size_t d=base.find_last_of('.');if(d!=std::string::npos)base=base.substr(0,d);
    size_t s=base.find_last_of('/');if(s!=std::string::npos)base=base.substr(s+1);
    std::string sb=base;std::replace(sb.begin(),sb.end(),'-','_');
    
    std::string cpp_file="/tmp/"+sb+".cpp";
    std::ofstream cf(cpp_file);cf<<transpile(code,fn);cf.close();
    
    bool has_browser=(code.find("DDLBrowser")!=std::string::npos);
    bool has_gfx=(code.find("DDLGraphic")!=std::string::npos);
    std::string bin="/tmp/"+sb+"_bin";
    
    if(system(bcmd(cpp_file,bin,has_gfx,has_browser).c_str())!=0){std::cerr<<"Compile failed\n";exit(1);}
    
    std::string pkg="/tmp/ddl_"+sb;
    system(("rm -rf "+pkg+"; mkdir -p "+pkg+"/DEBIAN "+pkg+"/usr/local/bin "+pkg+"/usr/share/"+sb).c_str());
    system(("cp "+bin+" "+pkg+"/usr/local/bin/"+sb+"; chmod 755 "+pkg+"/usr/local/bin/"+sb).c_str());
    
    std::ofstream ctrl(pkg+"/DEBIAN/control");
    ctrl<<"Package: "<<sb<<"\nVersion: 1.0.0\nArchitecture: amd64\nMaintainer: DDLanguage Team\nDescription: "<<base<<" - DDL App\n";
    ctrl.close();
    
    std::string deb=sb+"_1.0.0_amd64.deb";
    system(("fakeroot dpkg-deb --build "+pkg+" /tmp/"+deb+" 2>/dev/null; mv /tmp/"+deb+" ./"+deb+"; rm -rf "+pkg).c_str());
    std::cout<<"\033[32mExported: "<<deb<<"\033[0m\n";
}

int main(int argc,char* argv[]){
    if(argc<2){std::cout<<"DDL v"<<V<<"\n  cppddl file.ddl\n  cppddl --export file.ddl\n";return 0;}
    std::string arg=argv[1];
    if(arg=="--version"){std::cout<<"DDLanguage v"<<V<<"\n";return 0;}
    if(arg=="--export"){if(argc<3)return 1;export_deb(argv[2]);return 0;}
    run(arg);
    return 0;
}
CEOF

g++ -std=c++17 -o cppddl src/ddl_compiler.cpp -O2
echo -e "${GREEN}  cppddl compiled${NC}"

echo -e "${YELLOW}[4/5] Building .deb...${NC}"
DEB_NAME="cppddl_1.0.0_amd64"
DEB_DIR="deb/${DEB_NAME}"
rm -rf deb
mkdir -p "${DEB_DIR}/DEBIAN" "${DEB_DIR}/usr/local/bin" "${DEB_DIR}/usr/share/ddlanguage/include"
cp cppddl "${DEB_DIR}/usr/local/bin/"
chmod 755 "${DEB_DIR}/usr/local/bin/cppddl"
cp lib/ddl_runtime.h lib/ddl_browser_runtime.h "${DEB_DIR}/usr/share/ddlanguage/include/"

cat > "${DEB_DIR}/DEBIAN/control" << EOF
Package: cppddl
Version: 1.0.0
Section: devel
Priority: optional
Architecture: amd64
Depends: libc6, libstdc++6, g++, libgtk-3-0, libgtk-3-dev, libcairo2, libwebkit2gtk-4.1-0 | libwebkit2gtk-4.0-37, pkg-config, build-essential
Maintainer: DDLanguage Team
Description: DDLanguage v1.0 - Easiest programming language
EOF

cat > "${DEB_DIR}/DEBIAN/postinst" << 'POST'
#!/bin/bash
echo "DDLanguage v1.0 | cppddl file.ddl | cppddl --export file.ddl"
POST
chmod 755 "${DEB_DIR}/DEBIAN/postinst"

find "${DEB_DIR}" -type d -exec chmod 755 {} \;
find "${DEB_DIR}" -type f -exec chmod 644 {} \;
chmod 755 "${DEB_DIR}/usr/local/bin/cppddl" "${DEB_DIR}/DEBIAN/postinst"

fakeroot dpkg-deb --build "${DEB_DIR}" 2>/dev/null
cp "${DEB_DIR}.deb" "../${DEB_NAME}.deb"

cd ..
echo ""
echo -e "${GREEN}Done: ${DEB_NAME}.deb${NC}"
echo -e "Install: sudo dpkg -i ${DEB_NAME}.deb && sudo apt-get install -f"
