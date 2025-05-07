import sys
import os
import requests
import json
import time
import readline  # Para melhor suporte à entrada de texto no terminal

def converter_txt_para_json(caminho_txt, caminho_json):
    """Converte um arquivo .txt simples em um JSON estruturado por seções."""
    try:
        with open(caminho_txt, 'r', encoding='utf-8') as f:
            texto = f.read()

        secoes = {}
        secao_atual = "Introdução"
        linhas = texto.splitlines()

        for linha in linhas:
            linha = linha.strip()
            if not linha:
                continue
            if linha.lower().startswith("capítulo") or linha.lower().startswith("índice") or linha.lower().startswith("avisos"):
                secao_atual = linha
                secoes[secao_atual] = []
            else:
                secoes.setdefault(secao_atual, []).append(linha)

        json_data = {secao: " ".join(paragrafos) for secao, paragrafos in secoes.items()}

        with open(caminho_json, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, ensure_ascii=False, indent=2)

        print(f"Arquivo '{caminho_txt}' convertido com sucesso para '{caminho_json}'!")
        return caminho_json
    except Exception as e:
        print(f"Falha ao converter o manual de texto: {str(e)}")
        return None

class DeepseekAssistentVirtual:
    def __init__(self, model_name="deepseek-coder:6.7b-instruct", temperatura=0.7, manual_path=None):
        self.model_name = model_name
        self.temperatura = temperatura
        self.historico = []
        self.ollama_url = "http://localhost:11434/api/generate"
        self.manual_data = self.carregar_manual(manual_path)
        self.verificar_ollama()
        self.verificar_modelo()

    def verificar_ollama(self):
        try:
            response = requests.get("http://localhost:11434/api/version")
            if response.status_code == 200:
                print(f"Ollama está em execução: {response.json().get('version', 'versão desconhecida')}")
            else:
                print("Ollama está em execução, mas retornou um status inesperado.")
        except requests.exceptions.ConnectionError:
            print("\nErro: O Ollama não está em execução! Inicie o serviço Ollama.")
            print("   Execute 'ollama serve' em outro terminal ou certifique-se de que o serviço está ativo.")
            sys.exit(1)

    def verificar_modelo(self):
        try:
            url = "http://localhost:11434/api/tags"
            response = requests.get(url)
            modelos = response.json().get('models', [])
            modelo_disponivel = any(modelo['name'] == self.model_name for modelo in modelos)

            if not modelo_disponivel:
                print(f"\nO modelo {self.model_name} não está disponível. Baixando agora...")
                os.system(f"ollama pull {self.model_name}")
                print(f"Modelo {self.model_name} baixado com sucesso!")
            else:
                print(f"Modelo {self.model_name} está disponível e pronto para uso!")
        except Exception as e:
            print(f"Erro ao verificar o modelo: {e}")
            sys.exit(1)

    def carregar_manual(self, manual_path):
        if not manual_path or not os.path.exists(manual_path):
            print("Arquivo de manual não encontrado ou não especificado.")
            return None

        try:
            with open(manual_path, 'r', encoding='utf-8') as f:
                manual_data = json.load(f)
            print(f"Manual carregado com sucesso: {len(json.dumps(manual_data))} caracteres")
            return manual_data
        except Exception as e:
            print(f"Erro ao carregar o manual: {e}")
            return None

    def buscar_no_manual(self, query):
        if not self.manual_data:
            return "Não há manual carregado para consulta."
        keywords = query.lower().split()
        manual_str = json.dumps(self.manual_data, ensure_ascii=False).lower()
        if any(keyword in manual_str for keyword in keywords):
            contexto = "Informações relevantes do manual:\n\n"
            if isinstance(self.manual_data, dict):
                for chave, valor in self.manual_data.items():
                    if any(keyword in chave.lower() for keyword in keywords if isinstance(chave, str)):
                        contexto += f"- {chave}: {json.dumps(valor, ensure_ascii=False)[:500]}...\n"
                    if isinstance(valor, str) and any(keyword in valor.lower() for keyword in keywords):
                        contexto += f"- {chave}: {valor[:500]}...\n"
            elif isinstance(self.manual_data, list):
                for item in self.manual_data:
                    item_str = json.dumps(item, ensure_ascii=False).lower()
                    if any(keyword in item_str for keyword in keywords):
                        contexto += f"- {json.dumps(item, ensure_ascii=False)[:500]}...\n"
            return contexto if len(contexto) > 30 else "Nenhuma informação específica encontrada no manual."
        else:
            return "Não encontrei informações específicas sobre isso no manual."

    def gerar_resposta(self, prompt):
        contexto_manual = self.buscar_no_manual(prompt)
        prompt_enriquecido = f"""
        Pergunta: {prompt}

        {contexto_manual}

        Responda à pergunta com base nas informações acima do manual (se disponíveis) e em seu conhecimento.
        Se as informações do manual forem relevantes, destaque-as na resposta.
        """
        payload = {
            "model": self.model_name,
            "prompt": prompt_enriquecido,
            "stream": False,
            "temperature": self.temperatura
        }
        try:
            response = requests.post(self.ollama_url, json=payload)
            if response.status_code == 200:
                return response.json().get('response', 'Sem resposta')
            else:
                return f"Erro na solicitação: {response.status_code} - {response.text}"
        except Exception as e:
            return f"Erro de conexão: {str(e)}"

    def interagir(self):
        print(f"\nAssistente Virtual IBM com {self.model_name}")
        print("Este assistente pode responder perguntas usando o manual IBM e seu conhecimento interno.")
        if self.manual_data:
            print("Manual IBM carregado e pronto para consulta.")
        else:
            print("Nenhum manual carregado. Usando apenas o conhecimento interno do modelo.")
        print("\nComandos especiais:")
        print("  - 'sair', 'exit' ou 'quit': Encerrar o programa")
        print("  - 'manual': Ver informações sobre o manual carregado")
        print("  - 'ajuda': Mostrar esta mensagem de ajuda\n")

        while True:
            try:
                pergunta = input("\nVocê: ")
                if pergunta.lower() in ['sair', 'exit', 'quit']:
                    print("\nAté mais!")
                    break
                if not pergunta.strip():
                    continue
                if pergunta.lower() == 'ajuda':
                    print("\nComandos especiais:")
                    print("  - 'sair', 'exit' ou 'quit': Encerrar o programa")
                    print("  - 'manual': Ver informações sobre o manual carregado")
                    print("  - 'ajuda': Mostrar esta mensagem")
                    continue
                if pergunta.lower() == 'manual':
                    if self.manual_data:
                        manual_info = "Informações do manual carregado:\n"
                        if isinstance(self.manual_data, dict):
                            chaves = list(self.manual_data.keys())
                            manual_info += f"  - Tipo: Dicionário JSON\n"
                            manual_info += f"  - Chaves principais: {', '.join(chaves[:5])}"
                            if len(chaves) > 5:
                                manual_info += f" e mais {len(chaves) - 5} chaves"
                        elif isinstance(self.manual_data, list):
                            manual_info += f"  - Tipo: Lista JSON\n"
                            manual_info += f"  - Número de itens: {len(self.manual_data)}"
                        print(manual_info)
                    else:
                        print("Nenhum manual está carregado atualmente.")
                    continue
                print("\nAssistente: ", end="", flush=True)
                resposta = self.gerar_resposta(pergunta)
                print(resposta)
                self.historico.append({"pergunta": pergunta, "resposta": resposta})
            except KeyboardInterrupt:
                print("\n\nPrograma interrompido pelo usuário. Até mais!")
                break
            except Exception as e:
                print(f"\nErro: {str(e)}")

    def salvar_historico(self, arquivo="historico_conversas.json"):
        try:
            with open(arquivo, 'w', encoding='utf-8') as f:
                json.dump(self.historico, f, ensure_ascii=False, indent=4)
            print(f"\nHistórico salvo em '{arquivo}'")
        except Exception as e:
            print(f"\nErro ao salvar histórico: {str(e)}")

def main():
    modelo = "deepseek-coder:6.7b-instruct"
    manual_path = "./manual_convertido.json"  # Caminho fixo para o arquivo manual

    if len(sys.argv) > 1:
        modelo = sys.argv[1]

    if len(sys.argv) > 2:
        manual_path = sys.argv[2]
    else:
        if manual_path.endswith(".txt"):
            manual_json = manual_path.replace(".txt", ".json")
            manual_path = converter_txt_para_json(manual_path, manual_json)

    if not os.path.exists(manual_path):
        print(f"Arquivo não encontrado: {manual_path}")
        return

    assistente = DeepseekAssistentVirtual(model_name=modelo, manual_path=manual_path)
    try:
        assistente.interagir()
        if assistente.historico:
            salvar = input("\nDeseja salvar o histórico da conversa? (s/n): ")
            if salvar.lower() in ['s', 'sim', 'y', 'yes']:
                assistente.salvar_historico()
    except KeyboardInterrupt:
        print("\n\nPrograma interrompido. Até mais!")
    finally:
        print("\nObrigado por usar o Assistente Virtual com suporte ao manual IBM!")

if __name__ == "__main__":
    main()
