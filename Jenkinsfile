def repoName = "reblank/challenge2"
def versionTag = "${currentBuild.number}"
def kubeMaster = "https://AB896D0FA124C4F467684B5C1DC4B590.gr7.us-east-1.eks.amazonaws.com"

pipeline {
    agent none
    stages {
        stage('build & verify')
        {
            agent {
                docker { 
                    image 'nosinovacao/dotnet-sonar'
                    args '-v $HOME/.nuget/:/root/.nuget --net=host' }
            }
            stages{
                stage('Restore') {
                    steps {
                        git url: 'https://github.com/re-blank/dotnet-helloworld', branch: "main"
                        sh 'dotnet restore --packages /root/.nuget'
                    }
                    post
                    {
                        success{
                            slackSend(color: '#00FF00', message: "${currentBuild.displayName}'s restored dependencies")
                        }
                        failure{
                            slackSend(color: '#FF0000', message: "${currentBuild.displayName}'s failed to restore dependencies.")
                        }
                    }
                }
                
                stage('Build & SonarCloud') {
                    steps {
                        withSonarQubeEnv('SonarCloud'){
                            sh 'dotnet /sonar-scanner/SonarScanner.MSBuild.dll begin /k:"re-blank_dotnet-helloworld" /o:"re-blank"'
                            sh 'dotnet publish -o app --no-restore'
                            sh 'dotnet /sonar-scanner/SonarScanner.MSBuild.dll end'
                        }
                        
                    }
                    post
                    {
                        success{
                            slackSend(color: '#00FF00', message: "${currentBuild.displayName}'s .NET project built successfully.")
                        }
                        failure{
                            slackSend(color: '#FF0000', message: "${currentBuild.displayName}'s .NET project failed to build.")
                        }
                    }
                }
                stage('quality gate'){
                    steps{
                        withSonarQubeEnv('SonarCloud')
                        {
                            timeout(time: 10, unit: 'MINUTES') {
                                // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
                                // true = set pipeline to UNSTABLE, false = don't
                                waitForQualityGate abortPipeline: true
                            }
                        }
                    }
                    post
                    {
                        success{
                            slackSend(color: '#00FF00', message: "${currentBuild.displayName} passed the quality gate.")
                        }
                        failure{
                            slackSend(color: '#FF0000', message: "${currentBuild.displayName} failed the quality gate.")
                        }
                    }
                }
            }   
        }
        
        stage('Docker')
        {
            stages {
                stage('docker build') {   
                    agent {
                        docker { image 'docker' }
                    }
                    steps {
                        script {
                            image = docker.build(repoName+":${versionTag}")
                        }
                    }
                    post
                    {
                        success{
                            slackSend(color: '#00FF00', message: "${currentBuild.displayName}'s Docker image built successfully")
                        }
                        failure{
                            slackSend(color: '#FF0000', message: "${currentBuild.displayName}'s Docker image failed to build.")
                        }
                    }
                }
                stage('trivy') {
                    agent {
                        docker { 
                            image 'aquasec/trivy'
                            args '--net=host -v /var/run/docker.sock --entrypoint=' }
                    }
                    steps {
                        sh 'trivy image ' + "${repoName}:${versionTag}"
                    }
                    post
                    {
                        success{
                            slackSend(color: '#00FF00', message: "${currentBuild.displayName}'s trivy scan was successful")
                        }
                        failure{
                            slackSend(color: '#FF0000', message: "${currentBuild.displayName}'s trivy scan was unsuccessful")
                        }
                    }
                }
                
                stage('docker push') {
                    agent {
                        docker { image 'docker' }
                    }
                    steps {
                        script {
                            image = docker.image(repoName)
                            docker.withRegistry("", "docker_hub_credentials") {
                                image.push(versionTag)
                                image.push("latest")
                            }
                        }
                    }
                    post
                    {
                        success{
                            slackSend(color: '#00FF00', message: "${currentBuild.displayName}'s Docker image pushed to Docker Hub")
                        }
                        failure{
                            slackSend(color: '#FF0000', message: "${currentBuild.displayName}'s Docker image failed to push.")
                        }
                    }
                }
            }
            
        }

        stage('app deploy') {
            agent {
                docker { 
                    image 'reblank/kubectl_agent' 
                    args '--net=host'}
            }
            steps
            {
                git url: 'https://github.com/re-blank/dotnet-helloworld', branch: "main"
                withKubeConfig([credentialsId: 'kube-sa', serverUrl: "${kubeMaster}"]) {
                    sh 'kubectl apply -f kubernetes'
                }
            }
            post
            {
                success{
                    slackSend(color: '#00FF00', message: "${currentBuild.displayName} deployed to cluster.")
                }
                failure{
                    slackSend(color: '#FF0000', message: "${currentBuild.displayName} failed to deploy.")
                }
            }
        }
    }
}