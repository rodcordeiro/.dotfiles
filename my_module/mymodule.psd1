
@{

    # Arquivo de módulo de script ou módulo binário associado a este manifesto.
    RootModule        = 'mymodule.psm1'

    # Número da versão deste módulo.
    ModuleVersion     = '1.0.0'

    # PSEditions com suporte
    # CompatiblePSEditions = @()

    # ID usada para identificar este módulo de forma exclusiva
    GUID              = '5af698b0-2b23-4522-a600-bbe252f2a5b3'

    # Autor deste módulo
    Author            = 'Rodrigo Cordeiro <rodrigomendoncca@gmail.com> (http://rodcordeiro.com.br)'

    # Empresa ou fornecedor deste módulo
    CompanyName       = 'RodCordeiro'

    # Instrução de direitos autorais para este módulo
    Copyright         = '(c) 2022 Rodrigo Cordeiro. Todos os direitos reservados.'

    # Descrição da funcionalidade fornecida por este módulo
    Description       = 'Simple module with usefull scripts and automations'

    # A versão mínima do mecanismo do Windows PowerShell exigida por este módulo
    PowerShellVersion = '5.1'

    # Nome do host do Windows PowerShell exigido por este módulo
    # PowerShellHostName = ''

    # A versão mínima do host do Windows PowerShell exigida por este módulo
    # PowerShellHostVersion = ''

    # Versão mínima do Microsoft .NET Framework exigida por este módulo. Este pré-requisito é válido somente para a edição PowerShell Desktop.
    # DotNetFrameworkVersion = ''

    # A versão mínima do CLR (Common Language Runtime) exigida por este módulo. Este pré-requisito é válido somente para a edição PowerShell Desktop.
    # CLRVersion = ''

    # Arquitetura de processador (None, X86, Amd64, IA64) exigida por este módulo
    # ProcessorArchitecture = ''

    # Módulos que devem ser importados para o ambiente global antes da importação deste módulo
    # RequiredModules = @()

    # Assemblies que devem ser carregados antes da importação deste módulo
    # RequiredAssemblies = @()

    # Arquivos de script (.ps1) executados no ambiente do chamador antes da importação deste módulo.
    # ScriptsToProcess = @()

    # Arquivos de tipo (.ps1xml) a serem carregados durante a importação deste módulo
    # TypesToProcess = @()

    # Arquivos de formato (.ps1xml) a serem carregados na importação deste módulo
    # FormatsToProcess = @()

    # Módulos para importação como módulos aninhados do módulo especificado em RootModule/ModuleToProcess
    NestedModules     = @('.\imported_functions.psm1','.\authoral_functions.psm1')

    # Funções a serem exportadas deste módulo. Para melhor desempenho, não use curingas e não exclua a entrada. Use uma matriz vazia se não houver nenhuma função a ser exportada.
    FunctionsToExport = @('*')

    # Cmdlets a serem exportados deste módulo. Para melhor desempenho, não use curingas e não exclua a entrada. Use uma matriz vazia se não houver nenhum cmdlet a ser exportado.
    CmdletsToExport   = @()

    # Variáveis a serem exportadas deste módulo
    VariablesToExport = '*'

    # Aliases a serem exportados deste módulo. Para melhor desempenho, não use curingas e não exclua a entrada. Use uma matriz vazia se não houver nenhum alias a ser exportado.
    AliasesToExport   = @()

    # Recursos DSC a serem exportados deste módulo
    # DscResourcesToExport = @()

    # Lista de todos os módulos empacotados com este módulo
    # ModuleList = @()

    # Lista de todos os arquivos incluídos neste módulo
    # FileList = @()

    # Dados privados para passar para o módulo especificado em RootModule/ModuleToProcess. Também podem conter uma tabela de hash PSData com metadados adicionais do módulo usados pelo PowerShell.
    PrivateData       = @{
        PSData = @{
            Tags       = @('CLI', 'Automation', 'Publish')
            ProjectUri = 'https://github.com/rodcordeiro/.dotfiles'
            IconUri    = 'https://raw.githubusercontent.com/rodcordeiro/shares/master/img/logo.png'
            # Tags aplicadas a este módulo. Elas ajudam na descoberta de módulos em galerias online.
            # Tags = @()

            # Uma URL para a licença deste módulo.
            # LicenseUri = ''

            # Uma URL para o site principal deste projeto.
            # ProjectUri = ''

            # Uma URL para um ícone representando este módulo.
            # IconUri = ''

            # ReleaseNotes deste módulo
            # ReleaseNotes = ''
        }
    }



    # URI de HelpInfo deste módulo
    # HelpInfoURI = ''

    # Prefixo padrão dos comandos exportados deste módulo. Substitua o prefixo padrão usando Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

