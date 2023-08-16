pipeline {
    agent any

	triggers {
    	pollSCM('*/5 * * * *')
	}

    stages {
		stage ('FLUTTER DOCTOR') {
            steps {
                sh "flutter doctor -v"
            }
        }
        // stage('TEST') {
        //     steps {
        //         sh 'flutter test'
        //     }
        // }
        stage('BUILD') {
            steps {
                sh 'flutter build appbundle --debug'
            }
        }
		stage('DEPLOY') {
			steps {
				sh 'cd android && fastlane android deploy'
			}
		}
	}
}