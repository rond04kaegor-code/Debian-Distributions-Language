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
