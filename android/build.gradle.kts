// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    // Ajoutez ici d'autres plugins de projet si nécessaire



    id("com.google.gms.google-services") version "4.3.15" apply false // <--- C'est la ligne importante à ajouter/modifier ici !
}


allprojects {
    repositories {
        google() // <-- Très bien !
        mavenCentral() // <-- Très bien !
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
