# 🤖 Assistente Virtual IBM com Deepseek

Este projeto implementa um assistente virtual em Python que utiliza o modelo Deepseek 1.5B através da plataforma Ollama para fornecer respostas a perguntas sobre manuais da IBM e conhecimento geral.

## 📋 Requisitos

- Windows 10/11
- Permissões de administrador
- Conexão com a internet para download do modelo
- Arquivo de manual IBM em formato JSON (opcional)

## 🚀 Instalação e Configuração

### Passo 1: Instalar Ollama

Se você ainda não tem o Ollama instalado, execute o script `setup_ollama_model.ps1` com permissões de administrador:

```powershell
powershell -ExecutionPolicy Bypass -File setup_ollama_model.ps1
```

### Passo 2: Configurar o ambiente para o Assistente Virtual

Execute o script de configuração do ambiente com permissões de administrador:

```powershell
powershell -ExecutionPolicy Bypass -File setup_deepseek.ps1
```

Este script irá:
- Verificar se o Python está instalado (e instalar se necessário)
- Instalar as dependências Python necessárias
- Verificar se o Ollama está instalado e em execução
- Baixar o modelo Deepseek-Coder:lite, caso ainda não esteja disponível

## 💻 Utilização

Para iniciar o assistente virtual, execute:

```powershell
python assistente_virtual_deepseek.py
```

O assistente solicitará que você forneça o caminho para o arquivo JSON do manual IBM.

### Opções adicionais

Você pode especificar um modelo diferente e o caminho do manual:

```powershell
# Apenas com o modelo
python assistente_virtual_deepseek.py deepseek:1.5b

# Com modelo e manual
python assistente_virtual_deepseek.py deepseek:1.5b caminho/para/manual.json
```

## 📝 Comandos do Assistente

- Digite suas perguntas ou solicitações normalmente
- Digite `manual` para ver informações sobre o manual carregado
- Digite `ajuda` para ver a lista de comandos disponíveis
- Digite `sair`, `exit` ou `quit` para encerrar o programa
- Use Ctrl+C para interromper o programa a qualquer momento

## 🔄 Modelos disponíveis

O modelo Deepseek está disponível em diferentes tamanhos:

- `deepseek:1.5b` - Versão mais leve (recomendada para a maioria dos usuários)
- `deepseek:7b` - Versão média
- `deepseek:33b` - Versão completa (requer mais recursos)

## 📚 Formato do Manual JSON

O assistente é compatível com manuais da IBM em formato JSON. O arquivo pode ter as seguintes estruturas:
- Dicionário JSON com chaves representando tópicos ou seções
- Lista de objetos JSON contendo informações sobre produtos, comandos ou funcionalidades

O assistente tentará extrair informações relevantes do manual com base nas perguntas feitas.

## 📄 Salvamento de histórico

Ao encerrar o programa, você terá a opção de salvar o histórico da conversa em um arquivo JSON.

## ⚠️ Solução de problemas

- **Erro de conexão com Ollama**: Certifique-se de que o serviço Ollama está em execução. Execute `ollama serve` em um terminal separado.
- **Erro ao baixar modelo**: Verifique sua conexão com a internet e se há espaço suficiente em disco.
- **Python não encontrado**: Certifique-se de que o Python foi instalado corretamente e está no PATH do sistema.

## 📚 Recursos adicionais

- [Documentação do Ollama](https://ollama.ai/docs)
- [Modelos disponíveis no Ollama](https://ollama.ai/library)
- [Documentação do Deepseek Coder](https://github.com/deepseek-ai/deepseek-coder)