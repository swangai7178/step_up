allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val androidExtension = project.extensions.findByName("android")
            if (androidExtension != null) {
                val method = androidExtension.javaClass.getMethod("getNamespace")
                val currentNamespace = method.invoke(androidExtension)
                
                if (currentNamespace == null) {
                    val setNamespaceMethod = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespaceMethod.invoke(androidExtension, project.group.toString())
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}