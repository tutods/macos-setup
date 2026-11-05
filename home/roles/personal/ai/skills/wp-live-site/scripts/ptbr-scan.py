import re,sys
W=r'\b(tela|telas|celular|celulares|mouse|aplicativos?|arquivos?|usuári[oa]s?|baixar|contato|registrar|registro|câmera|esportiv\w*|monitorar|equipe|você|vocês|gente|planilha|salvar|deletar|conectar|conexão|conectado|plugar|pendrive|notebook|HD externo|controle|travar|trava|senha|fones?|caixa de som|gerenciador|gerenciar|tênis|time|xícara|ônibus|trem|legal|bacana|cadastr\w*|acessar|tchau|valeu|garoto|banheiro|geladeira|nuvem\w* de|detalhe|irmão|aliás|ótimo|ônibus|site oficial|baixe|clique aqui|pegar|colocar|tomada de rede|imagem do monitor|instalação limpa|SSD externo)\b'
G=r'\b\w{3,}ndo\b'
srcs=[(f,open(f).read()) for f in sys.argv[1:]] or [('-',sys.stdin.read())]
for f,s in srcs:
    for m in re.finditer(W,s,re.I): print(f,'WORD',m.group(0),'|',s[max(0,m.start()-40):m.end()+40].replace('\n',' '))
    for m in re.finditer(G,s,re.I):
        if m.group(0).lower() not in ('quando','segundo','mundo','fundo','redondo','fecundo'): print(f,'GERUND?',m.group(0),'|',s[max(0,m.start()-40):m.end()+40].replace('\n',' '))
