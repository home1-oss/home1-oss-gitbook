
# oss-release-spring-boot-1.4.2.RELEASE

Users of `spring-boot-1.4.2.RELEASE` needs to use `oss-release-spring-boot-1.4.2.RELEASE` 
and home1-oss libs that built and tested against `spring-boot-1.4.2.RELEASE`


Your project can use oss-release as parent and implicitly use oss-build as ancestor.

    <parent>
        <groupId>cn.home1</groupId>
        <artifactId>oss-release-spring-boot-1.4.2.RELEASE</artifactId>
        <version>${oss-release.version}</version>
    </parent>

or import in dependencyManagement.

    <!-- Use oss-build as parent is optional -->
    <parent>
        <groupId>cn.home1</groupId>
        <artifactId>oss-build</artifactId>
        <version>${oss-build.version}</version>
    </parent>
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>cn.home1</groupId>
                <artifactId>oss-release-spring-boot-1.4.2.RELEASE</artifactId>
                <version>${oss-release.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
