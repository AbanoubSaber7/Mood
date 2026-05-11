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

// Ensure Android library/application subprojects (plugins) have access to androidx.concurrent
// which provides CallbackToFutureAdapter used by some camera plugins.
subprojects {
    // Add dependency when an Android plugin is applied to the project
    plugins.withId("com.android.library") {
        dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.1.0")
        dependencies.add("implementation", "androidx.concurrent:concurrent-futures-ktx:1.1.0")
    }
    plugins.withId("com.android.application") {
        dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.1.0")
        dependencies.add("implementation", "androidx.concurrent:concurrent-futures-ktx:1.1.0")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
