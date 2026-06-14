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
