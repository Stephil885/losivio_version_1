allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// --- DÉBUT DU CORRECTIF (Version Kotlin) ---
subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.activity" && 
                requested.name.contains("activity")) {
                useVersion("1.9.3")
            }
        }
    }
}
// --- FIN DU CORRECTIF ---

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}