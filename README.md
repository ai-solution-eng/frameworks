# Frameworks

## Disclaimer

This repository contains helm charts adapted to be deployed on HPE Private Ccloud AI offering. They are NOT MEANT for production but for demo purposes and are provided without any warranty. For them, the MIT license apply, which is reported below:
```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Structure

Each framework has its own folder with the following content:

- a **logo** of the framework, to be used during the import process
- a **x.y.z** folder, relative to a specific version of the framework
- a **porting.md** file, describing how the framework has been ported to PCAI
- a **FRAMEWORK-x.y.z.tar.gz** file, which is the tar/gz file of the previous folder and FRAMEWORK is the name of the containing folder

Here are some references to follow:

- https://support.hpe.com/hpesc/public/docDisplay?docId=a00aie16hen_us&docLocale=en_US&page=ManageClusters/importing-applications.html
- https://github.com/HPEEzmeral/byoa-tutorials/blob/main/tutorial/README.md (this is older but still relevant)
