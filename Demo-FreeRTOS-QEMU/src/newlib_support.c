/* Minimal Newlib support shared by all boards. _write lives in the UART port;
 * libnosys supplies the remaining bare-metal defaults (including _sbrk).
 * No filesystem, input stream, or process model is provided by this demo. */
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>

/* Our startup files replace the toolchain CRT, including its _init hook. */
void _init(void)
{
}

int _close(int file)
{
    (void)file;
    errno = EBADF;
    return -1;
}

int _fstat(int file, struct stat *status)
{
    if (file >= 0 && file <= 2) {
        status->st_mode = S_IFCHR;
        return 0;
    }
    errno = EBADF;
    return -1;
}

int _isatty(int file)
{
    return file >= 0 && file <= 2;
}

off_t _lseek(int file, off_t offset, int direction)
{
    (void)file;
    (void)offset;
    (void)direction;
    errno = ESPIPE;
    return (off_t)-1;
}

int _read(int file, char *buffer, int length)
{
    (void)file;
    (void)buffer;
    (void)length;
    return 0;
}

int _getpid(void)
{
    return 1;
}

int _kill(int process, int signal)
{
    (void)process;
    (void)signal;
    errno = ENOSYS;
    return -1;
}
